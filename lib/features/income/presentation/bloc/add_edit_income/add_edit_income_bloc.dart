import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
// Import Unified Category entity
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/main.dart';

part 'add_edit_income_event.dart';
part 'add_edit_income_state.dart';

class AddEditIncomeBloc extends Bloc<AddEditIncomeEvent, AddEditIncomeState> {
  final AddIncomeUseCase _addIncomeUseCase;
  final UpdateIncomeUseCase _updateIncomeUseCase;
  final CategorizeTransactionUseCase _categorizeTransactionUseCase;
  final IncomeRepository _incomeRepository;
  final Uuid _uuid;

  AddEditIncomeBloc({
    required AddIncomeUseCase addIncomeUseCase,
    required UpdateIncomeUseCase updateIncomeUseCase,
    required CategorizeTransactionUseCase categorizeTransactionUseCase,
    required IncomeRepository incomeRepository,
    Income? initialIncome,
  })  : _addIncomeUseCase = addIncomeUseCase,
        _updateIncomeUseCase = updateIncomeUseCase,
        _categorizeTransactionUseCase = categorizeTransactionUseCase,
        _incomeRepository = incomeRepository,
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
    // Uses the correct Category type from the event
    final incomeToSave = Income(
      id: event.existingIncomeId ?? _uuid.v4(),
      title: event.title,
      amount: event.amount,
      date: event.date,
      category: event.category, // CORRECTED: Unified Category type
      accountId: event.accountId,
      notes: event.notes,
    );

    log.info(
        "[AddEditIncomeBloc] Calling ${isEditing ? 'Update' : 'Add'} use case for '${incomeToSave.title}'.");
    final Either<Failure, Income> saveResult = isEditing
        ? await _updateIncomeUseCase(UpdateIncomeParams(incomeToSave))
        : await _addIncomeUseCase(AddIncomeParams(incomeToSave));

    await saveResult.fold(
      (failure) async {
        /* ... error handling ... */
        log.warning("[AddEditIncomeBloc] Save failed: ${failure.message}");
        emit(state.copyWith(
            status: FormStatus.error,
            errorMessage: _mapFailureToMessage(failure)));
      },
      (savedIncome) async {
        /* ... success and categorization logic ... */
        log.info(
            "[AddEditIncomeBloc] Save successful for '${savedIncome.title}'. Now attempting categorization.");
        emit(state.copyWith(status: FormStatus.success));

        final categorizationParams = CategorizeTransactionParams(
            merchantId: null, description: savedIncome.title);
        final categorizationResult =
            await _categorizeTransactionUseCase(categorizationParams);

        await categorizationResult.fold((catFailure) async {
          log.warning(
              "[AddEditIncomeBloc] Categorization failed after save: ${catFailure.message}. Saving as Uncategorized.");
          await _incomeRepository.updateIncomeCategorization(
              savedIncome.id, null, CategorizationStatus.uncategorized, null);
          publishDataChangedEvent(
              type: DataChangeType.income,
              reason: isEditing
                  ? DataChangeReason.updated
                  : DataChangeReason.added);
        }, (catResult) async {
          log.info(
              "[AddEditIncomeBloc] Categorization successful. Status: ${catResult.status}, CatID: ${catResult.category?.id}, Conf: ${catResult.confidence}");
          await _incomeRepository.updateIncomeCategorization(savedIncome.id,
              catResult.category?.id, catResult.status, catResult.confidence);
          publishDataChangedEvent(
              type: DataChangeType.income,
              reason: isEditing
                  ? DataChangeReason.updated
                  : DataChangeReason.added);
        });
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    /* ... mapping logic ... */
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
