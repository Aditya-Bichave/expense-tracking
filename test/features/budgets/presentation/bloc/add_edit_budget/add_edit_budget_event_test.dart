import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';

void main() {
  group('AddEditBudgetEvent', () {
    group('InitializeBudgetForm', () {
      test('supports equality with same initialBudget', () {
        expect(
          const InitializeBudgetForm(initialBudget: null),
          equals(const InitializeBudgetForm(initialBudget: null)),
        );
      });

      test('can be created with null initialBudget', () {
        const event = InitializeBudgetForm(initialBudget: null);
        expect(event.initialBudget, null);
      });
    });

    group('SaveBudget', () {
      test('supports equality with same values', () {
        expect(
          SaveBudget(
            name: 'Test Budget',
            type: BudgetType.overall,
            targetAmount: 1000,
            period: BudgetPeriodType.monthly,
          ),
          equals(
            SaveBudget(
              name: 'Test Budget',
              type: BudgetType.overall,
              targetAmount: 1000,
              period: BudgetPeriodType.monthly,
            ),
          ),
        );
      });

      test('stores values correctly', () {
        final event = SaveBudget(
          name: 'Monthly Budget',
          type: BudgetType.categorySpecific,
          targetAmount: 500,
          period: BudgetPeriodType.monthly,
          categoryIds: ['cat1'],
          notes: 'Test notes',
        );

        expect(event.name, 'Monthly Budget');
        expect(event.type, BudgetType.categorySpecific);
        expect(event.targetAmount, 500);
        expect(event.period, BudgetPeriodType.monthly);
        expect(event.categoryIds, ['cat1']);
        expect(event.notes, 'Test notes');
      });
    });

    group('ClearBudgetFormMessage', () {
      test('supports equality', () {
        expect(
          const ClearBudgetFormMessage(),
          equals(const ClearBudgetFormMessage()),
        );
      });
    });
  });
}