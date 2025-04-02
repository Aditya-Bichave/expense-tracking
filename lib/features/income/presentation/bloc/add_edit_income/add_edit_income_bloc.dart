import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // Use shared FormStatus
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl helper & publish
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event
import 'package:expense_tracker/main.dart'; // Import logger

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
    log.info(
        "[AddEditIncomeBloc] Initialized. Editing: ${initialIncome != null}");
  }

  Future<void> _onSaveIncomeRequested(
      SaveIncomeRequested event, Emitter<AddEditIncomeState> emit) async {
    log.info("[AddEditIncomeBloc] Received SaveIncomeRequested.");
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

    log.info(
        "[AddEditIncomeBloc] Calling ${isEditing ? 'Update' : 'Add'} use case for '${incomeToSave.title}'.");
    final result = isEditing
        ? await _updateIncomeUseCase(UpdateIncomeParams(incomeToSave))
        : await _addIncomeUseCase(AddIncomeParams(incomeToSave));

    result.fold(
      (failure) {
        log.warning("[AddEditIncomeBloc] Save failed: ${failure.message}");
        emit(state.copyWith(
            status: FormStatus.error,
            errorMessage: _mapFailureToMessage(failure)));
      },
      (savedIncome) {
        log.info(
            "[AddEditIncomeBloc] Save successful for '${savedIncome.title}'. Emitting Success status and publishing event.");
        emit(state.copyWith(status: FormStatus.success));
        publishDataChangedEvent(
          type: DataChangeType.income,
          reason: isEditing ? DataChangeReason.updated : DataChangeReason.added,
        );
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
        "[AddEditIncomeBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return 'Database Error: Could not save income. ${failure.message}';
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
