// lib/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart'; // Updated import
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
// Use Cases
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/add_transfer.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/update_transfer.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
// Repositories
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
// Helpers
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart'; // Only needed for ValueGetter potentially
import 'package:uuid/uuid.dart';

part 'add_edit_transaction_event.dart';
part 'add_edit_transaction_state.dart';

class AddEditTransactionBloc
    extends Bloc<AddEditTransactionEvent, AddEditTransactionState> {
  final AddExpenseUseCase _addExpenseUseCase;
  final UpdateExpenseUseCase _updateExpenseUseCase;
  final AddIncomeUseCase _addIncomeUseCase;
  final UpdateIncomeUseCase _updateIncomeUseCase;
  final AddTransferUseCase _addTransferUseCase;
  final UpdateTransferUseCase _updateTransferUseCase;
  final CategorizeTransactionUseCase _categorizeTransactionUseCase;
  final CategoryRepository _categoryRepository;
  final Uuid _uuid;

  AddEditTransactionBloc({
    required AddExpenseUseCase addExpenseUseCase,
    required UpdateExpenseUseCase updateExpenseUseCase,
    required AddIncomeUseCase addIncomeUseCase,
    required UpdateIncomeUseCase updateIncomeUseCase,
    required AddTransferUseCase addTransferUseCase,
    required UpdateTransferUseCase updateTransferUseCase,
    required CategorizeTransactionUseCase categorizeTransactionUseCase,
    required ExpenseRepository expenseRepository,
    required IncomeRepository incomeRepository,
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
  })  : _addExpenseUseCase = addExpenseUseCase,
        _updateExpenseUseCase = updateExpenseUseCase,
        _addIncomeUseCase = addIncomeUseCase,
        _updateIncomeUseCase = updateIncomeUseCase,
        _addTransferUseCase = addTransferUseCase,
        _updateTransferUseCase = updateTransferUseCase,
        _categorizeTransactionUseCase = categorizeTransactionUseCase,
        _categoryRepository = categoryRepository,
        _uuid = const Uuid(),
        super(const AddEditTransactionState()) {
    on<InitializeTransaction>(_onInitializeTransaction);
    on<TransactionTypeChanged>(_onTransactionTypeChanged);
    on<SaveTransactionRequested>(_onSaveTransactionRequested);
    on<AcceptCategorySuggestion>(_onAcceptCategorySuggestion);
    on<RejectCategorySuggestion>(_onRejectCategorySuggestion);
    on<CreateCustomCategoryRequested>(_onCreateCustomCategoryRequested);
    on<CategoryCreated>(_onCategoryCreated);
    on<ClearMessages>(_onClearMessages);

    log.info("[AddEditTransactionBloc] Initialized.");
  }

  void _onInitializeTransaction(
    InitializeTransaction event,
    Emitter<AddEditTransactionState> emit,
  ) {
    log.info(
      "[AddEditTransactionBloc] Initializing. Has initial data: ${event.initialTransaction != null}",
    );
    if (event.initialTransaction != null) {
      final initial = event.initialTransaction!;
      emit(
        state.copyWith(
          transactionId: initial.id,
          category: () => initial.category,
          transactionType: initial.type,
          status: AddEditStatus.ready,
          // Store initial form values in temp fields
          tempTitle: initial.title,
          tempAmount: initial.amount,
          tempDate: initial.date,
          tempAccountId: initial.accountId,
          tempNotes: () => initial.notes, // Use ValueGetter for nullable notes
          clearErrorMessage: true,
        ),
      );
    } else {
      // Ensure temp fields are cleared when starting fresh
      emit(
        const AddEditTransactionState(
          status: AddEditStatus.ready,
        ).copyWith(clearTempData: true),
      );
    }
  }

  void _onTransactionTypeChanged(
    TransactionTypeChanged event,
    Emitter<AddEditTransactionState> emit,
  ) {
    log.info(
      "[AddEditTransactionBloc] Transaction Type Changed to: ${event.newType.name}",
    );
    if (state.transactionType != event.newType) {
      emit(
        state.copyWith(
          transactionType: event.newType,
          status: AddEditStatus.ready, // Reset status
          // Clear suggestion/newly created category when type changes
          clearSuggestion: true,
          clearNewlyCreated: true,
          clearCategory: true,
          clearErrorMessage: true,
        ),
      );
    }
  }

  Future<void> _onSaveTransactionRequested(
    SaveTransactionRequested event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    log.info(
      "[AddEditTransactionBloc] SaveRequested. Category selected: ${event.category?.name} (ID: ${event.category?.id})",
    );

    // Store form data in temp fields before potentially async operations
    emit(
      state.copyWith(
        status: AddEditStatus.loading, // Indicate processing start
        tempTitle: event.title,
        tempAmount: event.amount,
        tempDate: event.date,
        tempAccountId: event.fromAccountId,
        tempToAccountId: event.toAccountId,
        tempNotes: () => event.notes,
        clearErrorMessage: true,
        clearSuggestion: true,
        clearNewlyCreated: true,
      ),
    );

    if (state.transactionType == TransactionType.transfer) {
      await _performSave(
        null,
        emit,
      );
    } else if (event.category?.id == Category.uncategorized.id) {
      log.info(
        "[AddEditTransactionBloc] No specific category selected. Attempting auto-categorization...",
      );
      await _handleAutoCategorization(emit);
    } else {
      log.info(
        "[AddEditTransactionBloc] User selected specific category '${event.category?.name}'. Saving.",
      );
      // Directly proceed to save with the user-selected category
      await _performSave(
        event.category,
        emit,
        CategorizationStatus.categorized,
        1.0,
      );
    }
  }

  // --- Helper for Auto-Categorization ---
  Future<void> _handleAutoCategorization(
    Emitter<AddEditTransactionState> emit,
  ) async {
    final catParams = CategorizeTransactionParams(
      description: state.tempTitle ?? '',
      merchantId: null,
    ); // TODO: Get merchantId if available
    final catResult = await _categorizeTransactionUseCase(catParams);

    await catResult.fold(
      (failure) async {
        log.warning(
          "[AddEditTransactionBloc] Auto-categorization failed: ${failure.message}. Emitting AskingCreateCategory state.",
        );
        // Transition to a state indicating the user needs to choose creation or selection
        emit(state.copyWith(status: AddEditStatus.askingCreateCategory));
      },
      (result) async {
        if (result.category != null &&
            result.status == CategorizationStatus.needsReview) {
          log.info(
            "[AddEditTransactionBloc] Suggestion found: ${result.category!.name}. Emitting SuggestingCategory state.",
          );
          emit(
            state.copyWith(
              status: AddEditStatus.suggestingCategory,
              suggestedCategory: () => result.category,
            ),
          );
        } else {
          log.info(
            "[AddEditTransactionBloc] No suggestion or direct categorization. Emitting AskingCreateCategory state.",
          );
          emit(state.copyWith(status: AddEditStatus.askingCreateCategory));
        }
      },
    );
  }
  // --- End Helper ---

  Future<void> _onAcceptCategorySuggestion(
    AcceptCategorySuggestion event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    log.info(
      "[AddEditTransactionBloc] User accepted suggestion: ${event.suggestedCategory.name}",
    );
    // Suggestion accepted, proceed to save with this category
    await _performSave(
      event.suggestedCategory,
      emit,
      CategorizationStatus.categorized,
      1.0,
    );
  }

  void _onRejectCategorySuggestion(
    RejectCategorySuggestion event,
    Emitter<AddEditTransactionState> emit,
  ) {
    log.info(
      "[AddEditTransactionBloc] User rejected suggestion. Emitting AskingCreateCategory state.",
    );
    // Suggestion rejected, ask user if they want to create or select existing
    emit(
      state.copyWith(
        status: AddEditStatus.askingCreateCategory,
        clearSuggestion: true,
      ),
    );
  }

  void _onCreateCustomCategoryRequested(
    CreateCustomCategoryRequested event,
    Emitter<AddEditTransactionState> emit,
  ) {
    log.info(
      "[AddEditTransactionBloc] User requested to create custom category. Emitting navigation state.",
    );
    // Persist form data and transition to navigation state
    emit(
      state.copyWith(
        status: AddEditStatus.navigatingToCreateCategory,
        tempTitle: event.title,
        tempAmount: event.amount,
        tempDate: event.date,
        tempAccountId: event.accountId,
        tempNotes: () => event.notes,
      ),
    );
  }

  Future<void> _onCategoryCreated(
    CategoryCreated event,
    Emitter<AddEditTransactionState> emit,
  ) async {
    log.info(
      "[AddEditTransactionBloc] Received newly created category: ${event.newCategory.name}",
    );
    _categoryRepository.invalidateCache(); // Invalidate cache
    log.info("[AddEditTransactionBloc] Invalidated category cache.");

    // Set the newly created category and proceed to save
    emit(state.copyWith(newlyCreatedCategory: () => event.newCategory));
    // Add a small delay to increase chances of cache being ready if needed internally by save
    await Future.delayed(const Duration(milliseconds: 50));
    await _performSave(
      event.newCategory,
      emit,
      CategorizationStatus.categorized,
      1.0,
    );
  }

  void _onClearMessages(
    ClearMessages event,
    Emitter<AddEditTransactionState> emit,
  ) {
    // Reset to ready state when clearing messages, unless already successful
    final nextStatus = state.status == AddEditStatus.success
        ? AddEditStatus.success
        : AddEditStatus.ready;
    emit(state.copyWith(status: nextStatus, clearErrorMessage: true));
    log.info("[AddEditTransactionBloc] Cleared messages.");
  }

  // --- Central Save Logic ---
  Future<void> _performSave(
    Category? categoryToSave,
    Emitter<AddEditTransactionState> emit, [
    CategorizationStatus status = CategorizationStatus.categorized,
    double? confidence = 1.0,
  ]) async {
    log.info(
      "[AddEditTransactionBloc] _performSave called. Category To Use: ${categoryToSave?.name}, Status: $status",
    );
    emit(state.copyWith(status: AddEditStatus.saving));

    final isEditing = state.isEditing;
    final id = state.transactionId ?? _uuid.v4();
    final transactionType = state.transactionType;

    // Use temp data stored in the state
    final title = state.tempTitle ?? '';
    final amount = state.tempAmount ?? 0.0;
    final date = state.tempDate ?? DateTime.now();
    final fromAccountId = state.tempAccountId;
    final toAccountId = state.tempToAccountId;
    final notes = state.tempNotes;

    // Basic validation before proceeding
    if ((transactionType != TransactionType.transfer && title.isEmpty) || amount <= 0 || (transactionType != TransactionType.transfer && fromAccountId == null) || (transactionType == TransactionType.transfer && (fromAccountId == null || toAccountId == null))) {
      log.warning(
        "[AddEditTransactionBloc] Invalid data during _performSave. Aborting.",
      );
      emit(
        state.copyWith(
          status: AddEditStatus.error,
          errorMessage: () => "Missing required fields.",
        ),
      );
      return;
    }

    // Determine final category object and status
    Category? finalCategoryForEntity =
        categoryToSave?.id == Category.uncategorized.id ? null : categoryToSave;
    if (finalCategoryForEntity == null) {
      status = CategorizationStatus.uncategorized;
      confidence = null;
    }

    dynamic entityToSave;
    Either<Failure, dynamic> saveResult;

    // Create the final entity object
    if (transactionType == TransactionType.expense) {
      entityToSave = Expense(
        id: id,
        title: title,
        amount: amount,
        date: date,
        category: finalCategoryForEntity,
        accountId: fromAccountId!,
        status: status,
        confidenceScore: confidence,
      );
      log.info(
        "[AddEditTransactionBloc] Saving Expense (ID: $id) with Category ID: ${finalCategoryForEntity?.id}",
      );
      saveResult = isEditing
          ? await _updateExpenseUseCase(UpdateExpenseParams(entityToSave))
          : await _addExpenseUseCase(AddExpenseParams(entityToSave));
    } else if (transactionType == TransactionType.income) {
      // Income
      entityToSave = Income(
        id: id,
        title: title,
        amount: amount,
        date: date,
        category: finalCategoryForEntity,
        accountId: fromAccountId!,
        notes: notes,
        status: status,
        confidenceScore: confidence,
      );
      log.info(
        "[AddEditTransactionBloc] Saving Income (ID: $id) with Category ID: ${finalCategoryForEntity?.id}",
      );
      saveResult = isEditing
          ? await _updateIncomeUseCase(UpdateIncomeParams(entityToSave))
          : await _addIncomeUseCase(AddIncomeParams(entityToSave));
    } else {
      // Transfer
      entityToSave = Transaction(
        id: id,
        type: TransactionType.transfer,
        amount: amount,
        date: date,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
      );
      log.info(
        "[AddEditTransactionBloc] Saving Transfer (ID: $id)",
      );
      saveResult = isEditing
          ? await _updateTransferUseCase(UpdateTransferParams(entityToSave))
          : await _addTransferUseCase(AddTransferParams(entityToSave));
    }

    // Handle Save Result
    await saveResult.fold(
      (failure) async {
        log.warning("[AddEditTransactionBloc] Save failed: ${failure.message}");
        emit(
          state.copyWith(
            status: AddEditStatus.error,
            errorMessage: () => _mapFailureToMessage(failure),
            clearNewlyCreated: true,
          ),
        );
      },
      (savedEntity) async {
        log.info(
          "[AddEditTransactionBloc] Save successful for ID: ${savedEntity.id}.",
        );
        await Future.delayed(
          const Duration(milliseconds: 50),
        ); // Short delay before event/state change
        emit(
          state.copyWith(
            status: AddEditStatus.success,
            clearTempData: true,
            clearNewlyCreated: true,
          ),
        );
        publishDataChangedEvent(
          type: transactionType == TransactionType.expense
              ? DataChangeType.expense
              : DataChangeType.income,
          reason: isEditing ? DataChangeReason.updated : DataChangeReason.added,
        );
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
      "[AddEditTransactionBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}",
    );
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return 'Database Error: Could not save transaction. ${failure.message}';
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
