// lib/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/error/failure_extensions.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/delete_budget.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';

part 'budget_list_event.dart';
part 'budget_list_state.dart';

class BudgetListBloc extends Bloc<BudgetListEvent, BudgetListState> {
  final GetBudgetsUseCase _getBudgetsUseCase;
  final DeleteBudgetUseCase _deleteBudgetUseCase;
  final ExpenseRepository _expenseRepository;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  BudgetListBloc({
    required GetBudgetsUseCase getBudgetsUseCase,
    required DeleteBudgetUseCase deleteBudgetUseCase,
    required ExpenseRepository expenseRepository,
    required Stream<DataChangedEvent> dataChangeStream,
  }) : _getBudgetsUseCase = getBudgetsUseCase,
       _deleteBudgetUseCase = deleteBudgetUseCase,
       _expenseRepository = expenseRepository,
       super(const BudgetListState()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<_BudgetsDataChanged>(_onDataChanged);
    on<DeleteBudget>(_onDeleteBudget);
    on<ResetState>(_onResetState); // Add handler

    _dataChangeSubscription = dataChangeStream.listen((event) {
      // --- MODIFIED Listener ---
      if (event.type == DataChangeType.system &&
          event.reason == DataChangeReason.reset) {
        log.info(
          "[BudgetListBloc] System Reset event received. Adding ResetState.",
        );
        add(const ResetState());
      } else if (event.type == DataChangeType.budget ||
          event.type == DataChangeType.expense) {
        log.info(
          "[BudgetListBloc] Relevant DataChangedEvent ($event). Triggering reload.",
        );
        add(const _BudgetsDataChanged());
      }
      // --- END MODIFIED ---
    });
    log.info("[BudgetListBloc] Initialized.");
  }

  // --- ADDED: Reset State Handler ---
  void _onResetState(ResetState event, Emitter<BudgetListState> emit) {
    log.info("[BudgetListBloc] Resetting state to initial.");
    emit(const BudgetListState());
    add(const LoadBudgets()); // Trigger initial load after reset
  }
  // --- END ADDED ---

  // ... (rest of handlers remain the same) ...
  Future<void> _onDataChanged(
    _BudgetsDataChanged event,
    Emitter<BudgetListState> emit,
  ) async {
    // Avoid triggering reload if already loading/reloading
    if (state.status != BudgetListStatus.loading) {
      log.fine("[BudgetListBloc] Handling _DataChanged event.");
      add(const LoadBudgets(forceReload: true));
    } else {
      log.fine(
        "[BudgetListBloc] _DataChanged received, but already loading. Skipping explicit reload.",
      );
    }
  }

  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<BudgetListState> emit,
  ) async {
    // Prevent duplicate loading unless forced
    if (state.status == BudgetListStatus.loading && !event.forceReload) {
      log.fine("[BudgetListBloc] LoadBudgets ignored, already loading.");
      return;
    }

    log.info(
      "[BudgetListBloc] LoadBudgets triggered. ForceReload: ${event.forceReload}",
    );
    emit(state.copyWith(status: BudgetListStatus.loading, clearError: true));

    final budgetsResult = await _getBudgetsUseCase(const NoParams());

    await budgetsResult.fold(
      (failure) async {
        log.warning(
          "[BudgetListBloc] Failed to load budgets: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: BudgetListStatus.error,
            errorMessage: failure.toDisplayMessage(),
          ),
        );
      },
      (budgets) async {
        log.info(
          "[BudgetListBloc] Loaded ${budgets.length} budgets. Calculating status...",
        );
        List<BudgetWithStatus> budgetsWithStatusList = [];
        bool calculationErrorOccurred = false;
        String? firstCalcErrorMsg;

        // Define colors (could be moved to theme later)
        const thrivingColor = Colors.green; // Example
        const nearingLimitColor = Colors.orange; // Example
        const overLimitColor = Colors.red; // Example

        // Optimization: Fetch expenses once for the entire range needed
        if (budgets.isNotEmpty) {
          DateTime? minStart;
          DateTime? maxEnd;

          for (final budget in budgets) {
            final (periodStart, periodEnd) = budget.getCurrentPeriodDates();
            if (minStart == null || periodStart.isBefore(minStart)) {
              minStart = periodStart;
            }
            if (maxEnd == null || periodEnd.isAfter(maxEnd)) {
              maxEnd = periodEnd;
            }
          }

          log.info(
            "[BudgetListBloc] Fetching expenses for optimized calculation from $minStart to $maxEnd",
          );

          final expensesResult = await _expenseRepository.getExpenses(
            startDate: minStart,
            endDate: maxEnd,
          );

          await expensesResult.fold(
            (failure) async {
              log.warning(
                "[BudgetListBloc] Failed to fetch expenses: ${failure.message}",
              );
              calculationErrorOccurred = true;
              firstCalcErrorMsg = failure.toDisplayMessage();
            },
            (allExpenses) async {
              for (final budget in budgets) {
                final (periodStart, periodEnd) = budget.getCurrentPeriodDates();

                // Filter in memory
                double spent = 0;
                for (final expense in allExpenses) {
                  // Check date
                  if (expense.date.isBefore(periodStart) ||
                      expense.date.isAfter(
                        periodEnd
                            .add(const Duration(days: 1))
                            .subtract(const Duration(microseconds: 1)),
                      )) {
                    continue;
                  }

                  // Check category
                  bool categoryMatch = false;
                  if (budget.type == BudgetType.overall) {
                    categoryMatch = true;
                  } else if (budget.type == BudgetType.categorySpecific &&
                      budget.categoryIds != null &&
                      budget.categoryIds!.isNotEmpty) {
                    categoryMatch = budget.categoryIds!.contains(
                      expense.categoryId,
                    );
                  }

                  if (categoryMatch) {
                    spent += expense.amount;
                  }
                }

                budgetsWithStatusList.add(
                  BudgetWithStatus.calculate(
                    budget: budget,
                    amountSpent: spent,
                    thrivingColor: thrivingColor,
                    nearingLimitColor: nearingLimitColor,
                    overLimitColor: overLimitColor,
                  ),
                );
              }
            },
          );
        }

        if (calculationErrorOccurred) {
          // Emit error if any calculation failed, but still show successfully calculated budgets
          emit(
            state.copyWith(
              status: BudgetListStatus.error,
              budgetsWithStatus: budgetsWithStatusList, // Show what we have
              errorMessage:
                  firstCalcErrorMsg ?? "An unknown calculation error occurred.",
            ),
          );
        } else {
          log.info(
            "[BudgetListBloc] Successfully calculated status for all budgets.",
          );
          emit(
            state.copyWith(
              status: BudgetListStatus.success,
              budgetsWithStatus: budgetsWithStatusList,
              clearError: true,
            ),
          );
        }
      },
    );
  }

  Future<void> _onDeleteBudget(
    DeleteBudget event,
    Emitter<BudgetListState> emit,
  ) async {
    log.info(
      "[BudgetListBloc] DeleteBudget triggered for ID: ${event.budgetId}",
    );

    // Optimistic UI update - remove the item from the current list
    final optimisticList = state.budgetsWithStatus
        .where((bws) => bws.budget.id != event.budgetId)
        .toList();
    // Keep the current status unless it was error, then set to success optimistically
    final optimisticStatus = state.status == BudgetListStatus.error
        ? BudgetListStatus.success
        : state.status;
    emit(
      state.copyWith(
        budgetsWithStatus: optimisticList,
        status: optimisticStatus, // Assume success during operation
        clearError: true,
      ),
    );

    final result = await _deleteBudgetUseCase(
      DeleteBudgetParams(id: event.budgetId),
    );

    result.fold(
      (failure) {
        log.warning("[BudgetListBloc] Delete failed: ${failure.message}");
        // Revert UI implicitly by forcing a reload which will show the error state
        emit(
          state.copyWith(
            status: BudgetListStatus.error,
            errorMessage: failure.toDisplayMessage(
              context: "Failed to delete budget",
            ),
          ),
        );
        add(
          const LoadBudgets(forceReload: true),
        ); // Force reload to show error and potentially revert list if needed
      },
      (_) {
        log.info("[BudgetListBloc] Delete successful for ${event.budgetId}.");
        // Publish event - list will reload reactively via _onDataChanged
        publishDataChangedEvent(
          type: DataChangeType.budget,
          reason: DataChangeReason.deleted,
        );
        // No need to emit success state here, reactive reload handles it
      },
    );
  }

  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    log.info("[BudgetListBloc] Closed and cancelled data stream subscription.");
    return super.close();
  }
}
