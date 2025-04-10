// lib/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/delete_budget.dart'; // Import Delete UseCase
import 'package:expense_tracker/core/di/service_locator.dart'; // Import publishDataChangedEvent
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart'; // For colors

part 'budget_list_event.dart';
part 'budget_list_state.dart';

class BudgetListBloc extends Bloc<BudgetListEvent, BudgetListState> {
  final GetBudgetsUseCase _getBudgetsUseCase;
  final BudgetRepository _budgetRepository;
  final DeleteBudgetUseCase _deleteBudgetUseCase; // Added Delete UseCase
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  BudgetListBloc({
    required GetBudgetsUseCase getBudgetsUseCase,
    required BudgetRepository budgetRepository,
    required DeleteBudgetUseCase deleteBudgetUseCase, // Added requirement
    required Stream<DataChangedEvent> dataChangeStream,
  })  : _getBudgetsUseCase = getBudgetsUseCase,
        _budgetRepository = budgetRepository,
        _deleteBudgetUseCase = deleteBudgetUseCase, // Assign UseCase
        super(const BudgetListState()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<_BudgetsDataChanged>(_onDataChanged);
    on<DeleteBudget>(_onDeleteBudget); // Register handler

    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Reload budgets if Budgets change OR if Expenses change (affects calculation)
      if (event.type == DataChangeType.budget ||
          event.type == DataChangeType.expense) {
        log.info(
            "[BudgetListBloc] Relevant DataChangedEvent ($event). Triggering reload.");
        add(const _BudgetsDataChanged());
      }
    });
    log.info("[BudgetListBloc] Initialized.");
  }

  Future<void> _onDataChanged(
      _BudgetsDataChanged event, Emitter<BudgetListState> emit) async {
    // Avoid triggering reload if already loading/reloading
    if (state.status != BudgetListStatus.loading) {
      log.fine("[BudgetListBloc] Handling _DataChanged event.");
      add(const LoadBudgets(forceReload: true));
    } else {
      log.fine(
          "[BudgetListBloc] _DataChanged received, but already loading. Skipping explicit reload.");
    }
  }

  Future<void> _onLoadBudgets(
      LoadBudgets event, Emitter<BudgetListState> emit) async {
    // Prevent duplicate loading unless forced
    if (state.status == BudgetListStatus.loading && !event.forceReload) {
      log.fine("[BudgetListBloc] LoadBudgets ignored, already loading.");
      return;
    }

    log.info(
        "[BudgetListBloc] LoadBudgets triggered. ForceReload: ${event.forceReload}");
    emit(state.copyWith(status: BudgetListStatus.loading, clearError: true));

    final budgetsResult = await _getBudgetsUseCase(const NoParams());

    await budgetsResult.fold(
      (failure) async {
        log.warning(
            "[BudgetListBloc] Failed to load budgets: ${failure.message}");
        emit(state.copyWith(
            status: BudgetListStatus.error,
            errorMessage: _mapFailureToMessage(failure)));
      },
      (budgets) async {
        log.info(
            "[BudgetListBloc] Loaded ${budgets.length} budgets. Calculating status...");
        List<BudgetWithStatus> budgetsWithStatusList = [];
        bool calculationErrorOccurred = false;
        String? firstCalcErrorMsg;

        // Define colors (could be moved to theme later)
        // Consider getting these from Theme.of(context) if possible in BLoC, but safer here.
        const thrivingColor = Colors.green; // Example
        const nearingLimitColor = Colors.orange; // Example
        const overLimitColor = Colors.red; // Example

        // Calculate status for each budget sequentially
        for (final budget in budgets) {
          final (periodStart, periodEnd) = budget.getCurrentPeriodDates();
          final spentResult = await _budgetRepository.calculateAmountSpent(
            budget: budget,
            periodStart: periodStart,
            periodEnd: periodEnd,
          );

          spentResult.fold((failure) {
            log.warning(
                "[BudgetListBloc] Failed to calculate spent for '${budget.name}': ${failure.message}");
            calculationErrorOccurred = true;
            firstCalcErrorMsg ??=
                "Failed to calculate status for '${budget.name}': ${_mapFailureToMessage(failure)}";
          }, (amountSpent) {
            budgetsWithStatusList.add(BudgetWithStatus.calculate(
                budget: budget,
                amountSpent: amountSpent,
                thrivingColor: thrivingColor,
                nearingLimitColor: nearingLimitColor,
                overLimitColor: overLimitColor));
          });
          // Optional: Stop processing if a critical calculation error occurred
          if (calculationErrorOccurred &&
              firstCalcErrorMsg != null &&
              !firstCalcErrorMsg!.contains("Validation")) {
            break;
          }
        }

        if (calculationErrorOccurred) {
          // Emit error if any calculation failed, but still show successfully calculated budgets
          emit(state.copyWith(
            status: BudgetListStatus.error,
            budgetsWithStatus: budgetsWithStatusList, // Show what we have
            errorMessage:
                firstCalcErrorMsg ?? "An unknown calculation error occurred.",
          ));
        } else {
          log.info(
              "[BudgetListBloc] Successfully calculated status for all budgets.");
          emit(state.copyWith(
            status: BudgetListStatus.success,
            budgetsWithStatus: budgetsWithStatusList,
            clearError: true,
          ));
        }
      },
    );
  }

  Future<void> _onDeleteBudget(
      DeleteBudget event, Emitter<BudgetListState> emit) async {
    log.info(
        "[BudgetListBloc] DeleteBudget triggered for ID: ${event.budgetId}");

    // Optimistic UI update - remove the item from the current list
    final optimisticList = state.budgetsWithStatus
        .where((bws) => bws.budget.id != event.budgetId)
        .toList();
    // Keep the current status unless it was error, then set to success optimistically
    final optimisticStatus = state.status == BudgetListStatus.error
        ? BudgetListStatus.success
        : state.status;
    emit(state.copyWith(
        budgetsWithStatus: optimisticList,
        status: optimisticStatus, // Assume success during operation
        clearError: true));

    final result =
        await _deleteBudgetUseCase(DeleteBudgetParams(id: event.budgetId));

    result.fold(
      (failure) {
        log.warning("[BudgetListBloc] Delete failed: ${failure.message}");
        // Revert UI implicitly by forcing a reload which will show the error state
        emit(state.copyWith(
            status: BudgetListStatus.error,
            errorMessage: _mapFailureToMessage(failure,
                context: "Failed to delete budget")));
        add(const LoadBudgets(
            forceReload:
                true)); // Force reload to show error and potentially revert list if needed
      },
      (_) {
        log.info("[BudgetListBloc] Delete successful for ${event.budgetId}.");
        // Publish event - list will reload reactively via _onDataChanged
        publishDataChangedEvent(
            type: DataChangeType.budget, reason: DataChangeReason.deleted);
        // No need to emit success state here, reactive reload handles it
      },
    );
  }

  String _mapFailureToMessage(Failure failure,
      {String context = "An error occurred"}) {
    log.warning(
        "[BudgetListBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message; // Use validation message directly
      case CacheFailure:
        return '$context: Database Error: ${failure.message}';
      default:
        return '$context: An unexpected error occurred.';
    }
  }

  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    log.info("[BudgetListBloc] Closed and cancelled data stream subscription.");
    return super.close();
  }
}
