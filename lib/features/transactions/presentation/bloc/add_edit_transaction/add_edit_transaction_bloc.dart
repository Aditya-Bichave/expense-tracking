// ignore_for_file: unused_field

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
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
  final Uuid _uuid;

  AddEditTransactionBloc({
    required AddExpenseUseCase addExpenseUseCase,
    required UpdateExpenseUseCase updateExpenseUseCase,
    required AddIncomeUseCase addIncomeUseCase,
    required UpdateIncomeUseCase updateIncomeUseCase,
    required CategorizeTransactionUseCase categorizeTransactionUseCase,
    required ExpenseRepository expenseRepository,
    required IncomeRepository incomeRepository,
  })  : _addExpenseUseCase = addExpenseUseCase,
        _updateExpenseUseCase = updateExpenseUseCase,
        _addIncomeUseCase = addIncomeUseCase,
        _updateIncomeUseCase = updateIncomeUseCase,
        _categorizeTransactionUseCase = categorizeTransactionUseCase,
        _expenseRepository = expenseRepository,
        _incomeRepository = incomeRepository,
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
      InitializeTransaction event, Emitter<AddEditTransactionState> emit) {
    log.info(
        "[AddEditTransactionBloc] Initializing. Has initial data: ${event.initialTransaction != null}");
    if (event.initialTransaction != null) {
      emit(state.copyWith(
        initialTransaction: event.initialTransaction,
        transactionType: event.initialTransaction!.type,
        // --- Use correct enum ---
        status: AddEditStatus.ready,
        tempTitle: event.initialTransaction!.title,
        tempAmount: event.initialTransaction!.amount,
        tempDate: event.initialTransaction!.date,
        tempAccountId: event.initialTransaction!.accountId,
        tempNotes: () => event.initialTransaction!.notes,
      ));
    } else {
      // --- Use correct enum ---
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
        // --- Use correct enum ---
        status: AddEditStatus.ready,
        suggestedCategory: () => null,
        newlyCreatedCategory: () => null,
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
      askCreateCategory: false, // Reset ask flag on new save attempt
    ));

    if (event.category.id == Category.uncategorized.id) {
      log.info(
          "[AddEditTransactionBloc] No specific category selected. Attempting auto-categorization...");
      final catParams = CategorizeTransactionParams(
          description: event.title, merchantId: null);
      final catResult = await _categorizeTransactionUseCase(catParams);

      await catResult.fold((failure) async {
        log.warning(
            "[AddEditTransactionBloc] Auto-categorization failed: ${failure.message}. Asking user to Create Custom/Select.");
        // --- Use correct enum and new flag ---
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
            askCreateCategory: false, // Ensure ask flag is false here
          ));
        } else {
          log.info(
              "[AddEditTransactionBloc] No suggestion or direct categorization. Asking user to Create Custom/Select.");
          // --- Use correct enum and new flag ---
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

  Future<void> _onAcceptCategorySuggestion(AcceptCategorySuggestion event,
      Emitter<AddEditTransactionState> emit) async {
    log.info(
        "[AddEditTransactionBloc] User accepted suggestion: ${event.suggestedCategory.name}");
    // Clear suggestion flag and ask flag before saving
    emit(state.copyWith(clearSuggestion: true, askCreateCategory: false));
    await _performSave(
        event.suggestedCategory, emit, CategorizationStatus.categorized, 1.0);
  }

  Future<void> _onRejectCategorySuggestion(RejectCategorySuggestion event,
      Emitter<AddEditTransactionState> emit) async {
    log.info("[AddEditTransactionBloc] User rejected suggestion.");
    // Set state to trigger the "Ask Create Custom" dialog in the UI listener
    // --- Use correct enum and new flag ---
    emit(state.copyWith(
        status: AddEditStatus.ready,
        clearSuggestion: true,
        askCreateCategory: true));
  }

  void _onCreateCustomCategoryRequested(CreateCustomCategoryRequested event,
      Emitter<AddEditTransactionState> emit) {
    log.info(
        "[AddEditTransactionBloc] User requested to create custom category.");
    // Emit state to signal UI to navigate
    emit(state.copyWith(
      status: AddEditStatus.navigatingToCreateCategory,
      clearSuggestion: true,
      askCreateCategory: false, // Reset ask flag
    ));
  }

  Future<void> _onCategoryCreated(
      CategoryCreated event, Emitter<AddEditTransactionState> emit) async {
    log.info(
        "[AddEditTransactionBloc] Received newly created category: ${event.newCategory.name}");
    // Store the new category and immediately try saving with it
    emit(state.copyWith(
      newlyCreatedCategory: () => event.newCategory,
      // --- Use correct enum ---
      status: AddEditStatus.ready, // Ready to save with the new category
      askCreateCategory: false, // Ensure ask flag is false
    ));
    await _performSave(
        event.newCategory, emit, CategorizationStatus.categorized, 1.0);
  }

  void _onClearMessages(
      ClearMessages event, Emitter<AddEditTransactionState> emit) {
    // Only clear the error message, keep other state
    emit(state.copyWith(clearErrorMessage: true));
  }

  // --- Central Save Logic ---
  Future<void> _performSave(
      Category categoryToSave, Emitter<AddEditTransactionState> emit,
      [CategorizationStatus status = CategorizationStatus.categorized,
      double? confidence = 1.0]) async {
    log.info(
        "[AddEditTransactionBloc] _performSave called. Category: ${categoryToSave.name}, Status: $status");
    // Clear flags before emitting saving state
    emit(state.copyWith(
        status: AddEditStatus.saving,
        clearSuggestion: true,
        clearNewlyCreated: true,
        askCreateCategory: false // Ensure ask flag is false during save
        ));

    final isEditing = state.isEditing;
    final id = state.initialTransaction?.id ?? _uuid.v4();
    final transactionType = state.transactionType;

    dynamic entityToSave;
    Either<Failure, dynamic> saveResult;

    // Use temporary data stored in the state
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

    Category? finalCategory =
        categoryToSave.id == Category.uncategorized.id ? null : categoryToSave;
    if (finalCategory == null) {
      status = CategorizationStatus.uncategorized;
      confidence = null;
    }

    if (transactionType == TransactionType.expense) {
      entityToSave = Expense(
        id: id,
        title: title,
        amount: amount,
        date: date,
        category: finalCategory,
        accountId: accountId,
        status: status,
        confidenceScore: confidence,
      );
      log.info("[AddEditTransactionBloc] Saving Expense...");
      saveResult = isEditing
          ? await _updateExpenseUseCase(UpdateExpenseParams(entityToSave))
          : await _addExpenseUseCase(AddExpenseParams(entityToSave));
    } else {
      entityToSave = Income(
        id: id,
        title: title,
        amount: amount,
        date: date,
        category: finalCategory,
        accountId: accountId,
        notes: notes,
        status: status,
        confidenceScore: confidence,
      );
      log.info("[AddEditTransactionBloc] Saving Income...");
      saveResult = isEditing
          ? await _updateIncomeUseCase(UpdateIncomeParams(entityToSave))
          : await _addIncomeUseCase(AddIncomeParams(entityToSave));
    }

    await saveResult.fold(
      (failure) async {
        log.warning("[AddEditTransactionBloc] Save failed: ${failure.message}");
        emit(state.copyWith(
            status: AddEditStatus.error,
            errorMessage: () => _mapFailureToMessage(failure),
            clearTempData: true // Clear temp data on error
            ));
      },
      (savedEntity) async {
        log.info(
            "[AddEditTransactionBloc] Save successful for ID: ${savedEntity.id}.");
        emit(
            state.copyWith(status: AddEditStatus.success, clearTempData: true));
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
