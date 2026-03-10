import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportFilterState', () {
    test('initial factory creates expected state', () {
      final state = ReportFilterState.initial();
      expect(state.optionsStatus, equals(FilterOptionsStatus.initial));
      expect(state.availableCategories, isEmpty);
      expect(state.availableAccounts, isEmpty);
      expect(state.availableBudgets, isEmpty);
      expect(state.availableGoals, isEmpty);
      expect(state.selectedCategoryIds, isEmpty);
      expect(state.selectedAccountIds, isEmpty);
      expect(state.selectedBudgetIds, isEmpty);
      expect(state.selectedGoalIds, isEmpty);
      expect(state.selectedTransactionType, isNull);
    });

    test('copyWith works correctly', () {
      final state = ReportFilterState.initial();

      final newState = state.copyWith(
        optionsStatus: FilterOptionsStatus.loading,
        selectedCategoryIds: ['1'],
        selectedAccountIds: ['2'],
        selectedBudgetIds: ['3'],
        selectedGoalIds: ['4'],
      );

      expect(newState.optionsStatus, equals(FilterOptionsStatus.loading));
      expect(newState.selectedCategoryIds, equals(['1']));
      expect(newState.selectedAccountIds, equals(['2']));
      expect(newState.selectedBudgetIds, equals(['3']));
      expect(newState.selectedGoalIds, equals(['4']));

      final clearedState = newState.copyWith(
        clearDates: true,
        clearOptionsError: true,
        selectedTransactionTypeOrNull: () => null,
      );

      expect(clearedState.optionsError, isNull);
      expect(clearedState.selectedTransactionType, isNull);
    });
  });
}
