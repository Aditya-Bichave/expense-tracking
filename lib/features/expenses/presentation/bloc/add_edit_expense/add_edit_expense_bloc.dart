import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/main.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
// Import Unified Category entity
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';

part 'add_edit_expense_event.dart';
part 'add_edit_expense_state.dart';

class AddEditExpenseBloc
    extends Bloc<AddEditExpenseEvent, AddEditExpenseState> {
  final AddExpenseUseCase _addExpenseUseCase;
  final UpdateExpenseUseCase _updateExpenseUseCase;
  final CategorizeTransactionUseCase _categorizeTransactionUseCase;
  final ExpenseRepository _expenseRepository;
  final Uuid _uuid;

  AddEditExpenseBloc({
    required AddExpenseUseCase addExpenseUseCase,
    required UpdateExpenseUseCase updateExpenseUseCase,
    required CategorizeTransactionUseCase categorizeTransactionUseCase,
    required ExpenseRepository expenseRepository,
    Expense? initialExpense,
  })  : _addExpenseUseCase = addExpenseUseCase,
        _updateExpenseUseCase = updateExpenseUseCase,
        _categorizeTransactionUseCase = categorizeTransactionUseCase,
        _expenseRepository = expenseRepository,
        _uuid = const Uuid(),
        super(AddEditExpenseState(initialExpense: initialExpense)) {
    on<SaveExpenseRequested>(_onSaveExpenseRequested);
    log.info(
        "[AddEditExpenseBloc] Initialized. Editing: ${initialExpense != null}");
  }

  Future<void> _onSaveExpenseRequested(
      SaveExpenseRequested event, Emitter<AddEditExpenseState> emit) async {
    log.info("[AddEditExpenseBloc] Received SaveExpenseRequested.");
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));

    final bool isEditing = event.existingExpenseId != null;
    // Uses the correct Category type from the event
    final expenseToSave = Expense(
      id: event.existingExpenseId ?? _uuid.v4(),
      title: event.title,
      amount: event.amount,
      date: event.date,
      category: event.category, // This is now the unified Category type
      accountId: event.accountId,
    );

    log.info(
        "[AddEditExpenseBloc] Calling ${isEditing ? 'Update' : 'Add'} use case for '${expenseToSave.title}'.");
    final Either<Failure, Expense> saveResult = isEditing
        ? await _updateExpenseUseCase(UpdateExpenseParams(expenseToSave))
        : await _addExpenseUseCase(AddExpenseParams(expenseToSave));

    await saveResult.fold(
      (failure) async {
        log.warning("[AddEditExpenseBloc] Save failed: ${failure.message}");
        emit(state.copyWith(
            status: FormStatus.error,
            errorMessage: _mapFailureToMessage(failure)));
      },
      (savedExpense) async {
        log.info(
            "[AddEditExpenseBloc] Save successful for '${savedExpense.title}'. Now attempting categorization.");
        emit(state.copyWith(status: FormStatus.success));

        final categorizationParams = CategorizeTransactionParams(
          merchantId: null, // TODO: Extract merchant if available
          description: savedExpense.title,
        );
        final categorizationResult =
            await _categorizeTransactionUseCase(categorizationParams);

        await categorizationResult.fold((catFailure) async {
          log.warning(
              "[AddEditExpenseBloc] Categorization failed after save: ${catFailure.message}. Saving as Uncategorized.");
          await _expenseRepository.updateExpenseCategorization(
            savedExpense.id,
            null,
            CategorizationStatus.uncategorized,
            null,
          );
          publishDataChangedEvent(
              type: DataChangeType.expense,
              reason: isEditing
                  ? DataChangeReason.updated
                  : DataChangeReason.added);
        }, (catResult) async {
          log.info(
              "[AddEditExpenseBloc] Categorization successful. Status: ${catResult.status}, CatID: ${catResult.category?.id}, Conf: ${catResult.confidence}");
          await _expenseRepository.updateExpenseCategorization(
            savedExpense.id,
            catResult.category?.id,
            catResult.status,
            catResult.confidence,
          );
          publishDataChangedEvent(
              type: DataChangeType.expense,
              reason: isEditing
                  ? DataChangeReason.updated
                  : DataChangeReason.added);
        });
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
        "[AddEditExpenseBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return 'Database Error: Could not save expense. ${failure.message}';
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
