import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:expense_tracker/core/error/failure.dart';
// Assuming FormStatus enum is defined similarly to AddEditExpenseState or in a shared location
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart'; // Reusing FormStatus enum for simplicity
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart'; // Import IncomeCategory
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

part 'add_edit_income_event.dart';
part 'add_edit_income_state.dart';

class AddEditIncomeBloc extends Bloc<AddEditIncomeEvent, AddEditIncomeState> {
  final AddIncomeUseCase _addIncomeUseCase;
  final UpdateIncomeUseCase _updateIncomeUseCase;
  final Uuid _uuid;

  AddEditIncomeBloc({
    required AddIncomeUseCase addIncomeUseCase,
    required UpdateIncomeUseCase updateIncomeUseCase,
    Income? initialIncome,
  })  : _addIncomeUseCase = addIncomeUseCase,
        _updateIncomeUseCase = updateIncomeUseCase,
        _uuid = const Uuid(),
        super(AddEditIncomeState(initialIncome: initialIncome)) {
    on<SaveIncomeRequested>(_onSaveIncomeRequested);
  }

  Future<void> _onSaveIncomeRequested(
      SaveIncomeRequested event, Emitter<AddEditIncomeState> emit) async {
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));

    final bool isEditing = event.existingIncomeId != null;
    final incomeToSave = Income(
      id: event.existingIncomeId ?? _uuid.v4(),
      title: event.title,
      amount: event.amount,
      date: event.date,
      category: event.category,
      accountId: event.accountId,
      notes: event.notes,
    );

    final result = isEditing
        ? await _updateIncomeUseCase(UpdateIncomeParams(incomeToSave))
        : await _addIncomeUseCase(AddIncomeParams(incomeToSave));

    result.fold((failure) {
      emit(state.copyWith(
          status: FormStatus.error,
          errorMessage: _mapFailureToMessage(failure)));
    }, (_) {
      emit(state.copyWith(status: FormStatus.success));
      // *** Publish Event on Success ***
      publishDataChangedEvent(
          type: DataChangeType.income,
          reason:
              isEditing ? DataChangeReason.updated : DataChangeReason.added);
      // *********************************
    });
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
