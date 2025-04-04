import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // CategorizationStatus
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
// Use Cases
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
// Repositories
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart'; // Import Category Repo
// Helpers
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'add_edit_transaction_event.dart';
part 'add_edit_transaction_state.dart';

class AddEditTransactionBloc
    extends Bloc<AddEditTransactionEvent, AddEditTransactionState> {
  final AddExpenseUseCase _addExpenseUseCase;
  final UpdateExpenseUseCase _updateExpenseUseCase;
  final AddIncomeUseCase _addIncomeUseCase;
  final UpdateIncomeUseCase _updateIncomeUseCase;
  final CategorizeTransactionUseCase _categorizeTransactionUseCase;
  final ExpenseRepository _expenseRepository;
  final IncomeRepository _incomeRepository;
  final CategoryRepository _categoryRepository; // Add Category Repo
  final Uuid _uuid;

  AddEditTransactionBloc({
    required AddExpenseUseCase addExpenseUseCase,
    required UpdateExpenseUseCase updateExpenseUseCase,
    required AddIncomeUseCase addIncomeUseCase,
    required UpdateIncomeUseCase updateIncomeUseCase,
    required CategorizeTransactionUseCase categorizeTransactionUseCase,
    required ExpenseRepository expenseRepository,
    required IncomeRepository incomeRepository,
    required CategoryRepository categoryRepository, // Inject Category Repo
  })  : _addExpenseUseCase = addExpenseUseCase,
        _updateExpenseUseCase = updateExpenseUseCase,
        _addIncomeUseCase = addIncomeUseCase,
        _updateIncomeUseCase = updateIncomeUseCase,
        _categorizeTransactionUseCase = categorizeTransactionUseCase,
        _expenseRepository = expenseRepository,
        _incomeRepository = incomeRepository,
        _categoryRepository = categoryRepository, // Assign Category Repo
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

  // --- Keep _onInitializeTransaction, _onTransactionTypeChanged, _onSaveTransactionRequested ---
  // --- _askCreateCustomCategoryDialog, _onAcceptCategorySuggestion, _onRejectCategorySuggestion ---
  // --- _onCreateCustomCategoryRequested, _onClearMessages, _mapFailureToMessage AS THEY ARE ---
  void _onInitializeTransaction(
      InitializeTransaction event, Emitter<AddEditTransactionState> emit) {
    log.info(
        "[AddEditTransactionBloc] Initializing. Has initial data: ${event.initialTransaction != null}");
    if (event.initialTransaction != null) {
      emit(state.copyWith(
        initialTransaction: event.initialTransaction,
        transactionType: event.initialTransaction!.type,
        status: AddEditStatus.ready,
        tempTitle: event.initialTransaction!.title,
        tempAmount: event.initialTransaction!.amount,
        tempDate: event.initialTransaction!.date,
        tempAccountId: event.initialTransaction!.accountId,
        tempNotes: () => event.initialTransaction!.notes,
        clearAskCreateFlag: true,
        clearErrorMessage: true,
        clearSuggestion: true,
        clearNewlyCreated: true,
      ));
    } else {
      emit(const AddEditTransactionState(status: AddEditStatus.ready));
    }
  }

  void _onTransactionTypeChanged(
      TransactionTypeChanged event, Emitter<AddEditTransactionState> emit) {
    log.info(
        "[AddEditTransactionBloc] Transaction Type Changed to: ${event.newType.name}");
    if (state.transactionType != event.newType) {
      emit(state.copyWith(
        transactionType: event.newType,
        status: AddEditStatus.ready,
        suggestedCategory: () => null,
        newlyCreatedCategory: () => null,
        clearAskCreateFlag: true,
        clearErrorMessage: true,
      ));
    }
  }

  Future<void> _onSaveTransactionRequested(SaveTransactionRequested event,
      Emitter<AddEditTransactionState> emit) async {
    log.info(
        "[AddEditTransactionBloc] SaveRequested. Category selected: ${event.category.name} (ID: ${event.category.id})");

    emit(state.copyWith(
      status: AddEditStatus.loading,
      tempTitle: event.title,
      tempAmount: event.amount,
      tempDate: event.date,
      tempAccountId: event.accountId,
      tempNotes: () => event.notes,
      clearErrorMessage: true,
      clearSuggestion: true,
      clearNewlyCreated: true,
      clearAskCreateFlag: true,
    ));

    if (event.category.id == Category.uncategorized.id) {
      log.info(
          "[AddEditTransactionBloc] No specific category selected. Attempting auto-categorization...");
      final catParams = CategorizeTransactionParams(
          description: event.title, merchantId: null);
      final catResult = await _categorizeTransactionUseCase(catParams);

      await catResult.fold((failure) async {
        log.warning(
            "[AddEditTransactionBloc] Auto-categorization failed: ${failure.message}. Setting askCreateCategory flag.");
        emit(state.copyWith(
            status: AddEditStatus.ready, askCreateCategory: true));
      }, (result) async {
        if (result.category != null &&
            result.status == CategorizationStatus.needsReview) {
          log.info(
              "[AddEditTransactionBloc] Suggestion found: ${result.category!.name}. Emitting SuggestingCategory state.");
          emit(state.copyWith(
            status: AddEditStatus.suggestingCategory,
            suggestedCategory: () => result.category,
            clearAskCreateFlag: true,
          ));
        } else {
          log.info(
              "[AddEditTransactionBloc] No suggestion or direct categorization. Setting askCreateCategory flag.");
          emit(state.copyWith(
              status: AddEditStatus.ready, askCreateCategory: true));
        }
      });
    } else {
      log.info(
          "[AddEditTransactionBloc] User selected specific category '${event.category.name}'. Saving.");
      await _performSave(
          event.category, emit, CategorizationStatus.categorized, 1.0);
    }
  }

  void _askCreateCustomCategoryDialog(Emitter<AddEditTransactionState> emit) {
    emit(state.copyWith(
        status: AddEditStatus.ready,
        clearSuggestion: true,
        askCreateCategory: true // Set flag
        ));
  }

  Future<void> _onAcceptCategorySuggestion(AcceptCategorySuggestion event,
      Emitter<AddEditTransactionState> emit) async {
    log.info(
        "[AddEditTransactionBloc] User accepted suggestion: ${event.suggestedCategory.name}");
    emit(state.copyWith(clearSuggestion: true, clearAskCreateFlag: true));
    await _performSave(
        event.suggestedCategory, emit, CategorizationStatus.categorized, 1.0);
  }

  Future<void> _onRejectCategorySuggestion(RejectCategorySuggestion event,
      Emitter<AddEditTransactionState> emit) async {
    log.info(
        "[AddEditTransactionBloc] User rejected suggestion. Setting askCreateCategory flag.");
    emit(state.copyWith(
        status: AddEditStatus.ready,
        clearSuggestion: true,
        askCreateCategory: true));
  }

  void _onCreateCustomCategoryRequested(CreateCustomCategoryRequested event,
      Emitter<AddEditTransactionState> emit) {
    log.info(
        "[AddEditTransactionBloc] User requested to create custom category. Emitting navigation state.");
    emit(state.copyWith(
        status: AddEditStatus.navigatingToCreateCategory,
        clearSuggestion: true,
        clearAskCreateFlag: true));
  }

  Future<void> _onCategoryCreated(
      CategoryCreated event, Emitter<AddEditTransactionState> emit) async {
    log.info(
        "[AddEditTransactionBloc] Received newly created category: ${event.newCategory.name}");

    // --- Invalidate Category Cache AFTER category is created ---
    log.info(
        "[AddEditTransactionBloc] Invalidating category repository cache.");
    _categoryRepository.invalidateCache();
    // --- End Invalidation ---

    emit(state.copyWith(
        newlyCreatedCategory: () => event.newCategory,
        status: AddEditStatus.loading, // Show loading before save
        clearAskCreateFlag: true));
    // Add a tiny delay to increase chances of cache being ready for _performSave's internal fetch
    await Future.delayed(const Duration(milliseconds: 50));
    await _performSave(
        event.newCategory, emit, CategorizationStatus.categorized, 1.0);
  }

  void _onClearMessages(
      ClearMessages event, Emitter<AddEditTransactionState> emit) {
    emit(state.copyWith(
        status: (state.status == AddEditStatus.error)
            ? AddEditStatus.ready
            : state.status,
        clearErrorMessage: true,
        clearAskCreateFlag: true));
    log.info("[AddEditTransactionBloc] Cleared messages.");
  }

  // --- Central Save Logic ---
  Future<void> _performSave(
      Category categoryToSave, Emitter<AddEditTransactionState> emit,
      [CategorizationStatus status = CategorizationStatus.categorized,
      double? confidence = 1.0]) async {
    // --- Use categoryToSave directly, no need to prioritize newlyCreatedCategory from state here ---
    // final Category categoryToUse = state.newlyCreatedCategory ?? categoryToSave;
    final Category categoryToUse = categoryToSave;

    log.info(
        "[AddEditTransactionBloc] _performSave called. Category To Use: ${categoryToUse.name}, Status: $status");
    emit(state.copyWith(
        status: AddEditStatus.saving,
        clearSuggestion: true,
        clearNewlyCreated: true,
        clearAskCreateFlag: true));

    final isEditing = state.isEditing;
    final id = state.initialTransaction?.id ?? _uuid.v4();
    final transactionType = state.transactionType;

    dynamic entityToSave;
    Either<Failure, dynamic> saveResult;

    final title = state.tempTitle ?? '';
    final amount = state.tempAmount ?? 0.0;
    final date = state.tempDate ?? DateTime.now();
    final accountId = state.tempAccountId ?? '';
    final notes = state.tempNotes;

    if (title.isEmpty || amount <= 0 || accountId.isEmpty) {
      log.warning(
          "[AddEditTransactionBloc] Invalid data during _performSave. Aborting.");
      emit(state.copyWith(
          status: AddEditStatus.error,
          errorMessage: () => "Missing required fields.",
          clearTempData: true));
      return;
    }

    Category? finalCategoryForEntity =
        categoryToUse.id == Category.uncategorized.id ? null : categoryToUse;
    if (finalCategoryForEntity == null) {
      status = CategorizationStatus.uncategorized;
      confidence = null;
    }

    // Create the final entity object
    if (transactionType == TransactionType.expense) {
      entityToSave = Expense(
        id: id,
        title: title,
        amount: amount,
        date: date,
        category: finalCategoryForEntity,
        accountId: accountId,
        status: status,
        confidenceScore: confidence,
      );
      log.info(
          "[AddEditTransactionBloc] Saving Expense (ID: $id) with Category ID: ${finalCategoryForEntity?.id}");
      saveResult = isEditing
          ? await _updateExpenseUseCase(UpdateExpenseParams(entityToSave))
          : await _addExpenseUseCase(AddExpenseParams(entityToSave));
    } else {
      // Income
      entityToSave = Income(
        id: id,
        title: title,
        amount: amount,
        date: date,
        category: finalCategoryForEntity,
        accountId: accountId,
        notes: notes,
        status: status,
        confidenceScore: confidence,
      );
      log.info(
          "[AddEditTransactionBloc] Saving Income (ID: $id) with Category ID: ${finalCategoryForEntity?.id}");
      saveResult = isEditing
          ? await _updateIncomeUseCase(UpdateIncomeParams(entityToSave))
          : await _addIncomeUseCase(AddIncomeParams(entityToSave));
    }

    // Handle Save Result
    await saveResult.fold(
      (failure) async {
        log.warning("[AddEditTransactionBloc] Save failed: ${failure.message}");
        emit(state.copyWith(
            status: AddEditStatus.error,
            errorMessage: () => _mapFailureToMessage(failure),
            clearTempData: true,
            clearNewlyCreated:
                true // Clear any potentially stored new category on error
            ));
      },
      (savedEntity) async {
        // --- Remove internal re-fetch - rely on DataChangedEvent and list reload ---
        // Category? finalHydratedCategory = finalCategoryForEntity;
        // if (finalHydratedCategory != null) { ... re-fetch logic removed ... }
        // --- End Removal ---

        log.info(
            "[AddEditTransactionBloc] Save successful for ID: ${savedEntity.id}.");

        // --- ADD Delay before publishing event ---
        await Future.delayed(const Duration(milliseconds: 100)); // Small delay
        // --- End Delay ---

        // Emit success first
        emit(state.copyWith(
            status: AddEditStatus.success,
            clearTempData: true,
            clearNewlyCreated: true));

        // Then publish event
        publishDataChangedEvent(
            type: transactionType == TransactionType.expense
                ? DataChangeType.expense
                : DataChangeType.income,
            reason:
                isEditing ? DataChangeReason.updated : DataChangeReason.added);
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
        "[AddEditTransactionBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
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
