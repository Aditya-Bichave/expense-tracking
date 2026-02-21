import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';

void main() {
  group('BudgetListEvent', () {
    group('LoadBudgets', () {
      test('supports equality with default forceReload', () {
        expect(const LoadBudgets(), equals(const LoadBudgets()));
      });

      test('supports equality with same forceReload value', () {
        expect(
          const LoadBudgets(forceReload: true),
          equals(const LoadBudgets(forceReload: true)),
        );
      });

      test('has correct default forceReload value', () {
        const event = LoadBudgets();
        expect(event.forceReload, false);
      });

      test('stores forceReload value correctly', () {
        const event = LoadBudgets(forceReload: true);
        expect(event.forceReload, true);
      });
    });

    group('DeleteBudget', () {
      test('supports equality with same budgetId', () {
        expect(
          const DeleteBudget('123'),
          equals(const DeleteBudget('123')),
        );
      });

      test('supports inequality with different budgetId', () {
        expect(
          const DeleteBudget('123'),
          isNot(equals(const DeleteBudget('456'))),
        );
      });

      test('stores budgetId correctly', () {
        const event = DeleteBudget('test-id');
        expect(event.budgetId, 'test-id');
      });
    });

    group('ResetState', () {
      test('supports equality', () {
        expect(const ResetState(), equals(const ResetState()));
      });
    });
  });
}