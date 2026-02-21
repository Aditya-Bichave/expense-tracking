import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';

void main() {
  final tBudget = Budget(
    id: '1',
    name: 'Test Budget',
    type: BudgetType.overall,
    targetAmount: 100.0,
    period: BudgetPeriodType.recurringMonthly,
    createdAt: DateTime(2023, 1, 1),
  );

  const tThrivingColor = Colors.green;
  const tNearingLimitColor = Colors.orange;
  const tOverLimitColor = Colors.red;

  group('BudgetWithStatus', () {
    test('calculate should return correct status for thriving (<= 75%)', () {
      final status = BudgetWithStatus.calculate(
        budget: tBudget,
        amountSpent: 50.0, // 50%
        thrivingColor: tThrivingColor,
        nearingLimitColor: tNearingLimitColor,
        overLimitColor: tOverLimitColor,
      );

      expect(status.budget, tBudget);
      expect(status.amountSpent, 50.0);
      expect(status.amountRemaining, 50.0);
      expect(status.percentageUsed, 0.5);
      expect(status.health, BudgetHealth.thriving);
      expect(status.statusColor, tThrivingColor);
    });

    test(
      'calculate should return correct status for nearing limit (> 75% && <= 100%)',
      () {
        final status = BudgetWithStatus.calculate(
          budget: tBudget,
          amountSpent: 80.0, // 80%
          thrivingColor: tThrivingColor,
          nearingLimitColor: tNearingLimitColor,
          overLimitColor: tOverLimitColor,
        );

        expect(status.health, BudgetHealth.nearingLimit);
        expect(status.statusColor, tNearingLimitColor);
        expect(status.percentageUsed, 0.8);
        expect(status.amountRemaining, 20.0);
      },
    );

    test('calculate should return correct status for over limit (> 100%)', () {
      final status = BudgetWithStatus.calculate(
        budget: tBudget,
        amountSpent: 110.0, // 110%
        thrivingColor: tThrivingColor,
        nearingLimitColor: tNearingLimitColor,
        overLimitColor: tOverLimitColor,
      );

      expect(status.health, BudgetHealth.overLimit);
      expect(status.statusColor, tOverLimitColor);
      expect(status.percentageUsed, 1.1);
      expect(status.amountRemaining, -10.0);
    });

    test('calculate should handle 0 target amount', () {
      final zeroBudget = tBudget.copyWith(targetAmount: 0.0);
      final status = BudgetWithStatus.calculate(
        budget: zeroBudget,
        amountSpent: 0.0,
        thrivingColor: tThrivingColor,
        nearingLimitColor: tNearingLimitColor,
        overLimitColor: tOverLimitColor,
      );

      expect(status.percentageUsed, 0.0);
      expect(status.health, BudgetHealth.thriving);
      expect(status.amountRemaining, 0.0);
    });
  });
}
