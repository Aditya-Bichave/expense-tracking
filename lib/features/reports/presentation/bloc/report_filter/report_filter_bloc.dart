// lib/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart'; // Added
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart'; // Added
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart'; // Added
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart'; // Added
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart'; // Added
import 'package:expense_tracker/main.dart';
import 'package:flutter/foundation.dart' hide Category; // Added for ValueGetter

part 'report_filter_event.dart';
part 'report_filter_state.dart';

class ReportFilterBloc extends Bloc<ReportFilterEvent, ReportFilterState> {
  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetAssetAccountsUseCase _getAssetAccountsUseCase;
  // --- ADDED Dependencies ---
  final GetBudgetsUseCase _getBudgetsUseCase;
  final GetGoalsUseCase _getGoalsUseCase;
  // --- END ADDED ---

  ReportFilterBloc({
    required GetCategoriesUseCase
    categoryRepository, // Name kept for compatibility
    required GetAssetAccountsUseCase
    accountRepository, // Name kept for compatibility
    required GetBudgetsUseCase budgetRepository, // Use correct type
    required GetGoalsUseCase goalRepository, // Use correct type
  }) : _getCategoriesUseCase = categoryRepository,
       _getAssetAccountsUseCase = accountRepository,
       _getBudgetsUseCase = budgetRepository, // Assign
       _getGoalsUseCase = goalRepository, // Assign
       super(ReportFilterState.initial()) {
    on<LoadFilterOptions>(_onLoadFilterOptions);
    on<UpdateReportFilters>(_onUpdateReportFilters);
    on<ClearReportFilters>(_onClearReportFilters);

    log.info("[ReportFilterBloc] Initialized.");
    add(const LoadFilterOptions());
  }

  Future<void> _onLoadFilterOptions(
    LoadFilterOptions event,
    Emitter<ReportFilterState> emit,
  ) async {
    if (state.optionsStatus == FilterOptionsStatus.loaded &&
        !event.forceReload) {
      log.info("[ReportFilterBloc] Filter options already loaded.");
      return;
    }
    log.info("[ReportFilterBloc] Loading filter options...");
    emit(state.copyWith(optionsStatus: FilterOptionsStatus.loading));

    String? errorMsg;
    List<Category> categories = [];
    List<AssetAccount> accounts = [];
    List<Budget> budgets = []; // Added
    List<Goal> goals = []; // Added

    // Fetch all options concurrently
    final results = await Future.wait([
      _getCategoriesUseCase(const NoParams()),
      _getAssetAccountsUseCase(const NoParams()),
      _getBudgetsUseCase(const NoParams()), // Added
      _getGoalsUseCase(const NoParams()), // Added
    ]);

    // Process results
    (results[0] as Either<Failure, List<Category>>).fold(
      (f) => errorMsg = _appendError(errorMsg, "Failed to load categories."),
      (c) => categories = c,
    );
    (results[1] as Either<Failure, List<AssetAccount>>).fold(
      (f) => errorMsg = _appendError(errorMsg, "Failed to load accounts."),
      (a) => accounts = a,
    );
    (results[2] as Either<Failure, List<Budget>>).fold(
      // Added
      (f) => errorMsg = _appendError(errorMsg, "Failed to load budgets."),
      (b) => budgets = b,
    );
    (results[3] as Either<Failure, List<Goal>>).fold(
      // Added
      (f) => errorMsg = _appendError(errorMsg, "Failed to load goals."),
      (g) => goals = g,
    );

    if (errorMsg != null) {
      log.warning("[ReportFilterBloc] Error loading filter options: $errorMsg");
      emit(
        state.copyWith(
          optionsStatus: FilterOptionsStatus.error,
          optionsError: errorMsg,
        ),
      );
    } else {
      log.info(
        "[ReportFilterBloc] Filter options loaded successfully (Cats: ${categories.length}, Accs: ${accounts.length}, Budgets: ${budgets.length}, Goals: ${goals.length}).",
      );
      emit(
        state.copyWith(
          optionsStatus: FilterOptionsStatus.loaded,
          availableCategories: categories,
          availableAccounts: accounts,
          availableBudgets: budgets, // Added
          availableGoals: goals, // Added
          optionsError: null, // Clear previous error
        ),
      );
    }
  }

  void _onUpdateReportFilters(
    UpdateReportFilters event,
    Emitter<ReportFilterState> emit,
  ) {
    log.info("[ReportFilterBloc] Updating filters.");
    emit(
      state.copyWith(
        startDate: event.startDate,
        endDate: event.endDate,
        selectedCategoryIds: event.categoryIds,
        selectedAccountIds: event.accountIds,
        selectedBudgetIds: event.budgetIds, // Added
        selectedGoalIds: event.goalIds, // Added
        // --- UPDATED to use ValueGetter for nullable type ---
        selectedTransactionTypeOrNull: () => event.transactionType, // Added
        // --- END UPDATED ---
        clearDates: event.startDate == null && event.endDate == null,
      ),
    );
  }

  void _onClearReportFilters(
    ClearReportFilters event,
    Emitter<ReportFilterState> emit,
  ) {
    log.info("[ReportFilterBloc] Clearing all filters.");
    emit(
      state.copyWith(
        startDate: null, // Will be reset by copyWith logic
        endDate: null, // Will be reset by copyWith logic
        selectedCategoryIds: [],
        selectedAccountIds: [],
        selectedBudgetIds: [], // Added
        selectedGoalIds: [], // Added
        selectedTransactionTypeOrNull: () => null, // Added clear
        clearDates: true,
      ),
    );
  }

  String _appendError(String? current, String message) {
    if (current == null) return message;
    return "$current\n$message";
  }
}
