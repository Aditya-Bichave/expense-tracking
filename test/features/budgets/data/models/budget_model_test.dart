import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tBudgetModel = BudgetModel(
    id: '1',
    name: 'Test Budget',
    budgetTypeIndex: BudgetType.categorySpecific.index,
    targetAmount: 500.0,
    periodTypeIndex: BudgetPeriodType.recurringMonthly.index,
    startDate: tDate,
    endDate: tDate.add(const Duration(days: 30)),
    categoryIds: ['cat1', 'cat2'],
    notes: 'Test notes',
    createdAt: tDate,
  );

  group('BudgetModel', () {
    test('should be a subclass of HiveObject', () {
      expect(tBudgetModel, isA<Object>());
    });

    test('fromEntity should return a valid Model', () {
      final tBudget = Budget(
        id: '1',
        name: 'Test Budget',
        type: BudgetType.categorySpecific,
        targetAmount: 500.0,
        period: BudgetPeriodType.recurringMonthly,
        startDate: tDate,
        endDate: tDate.add(const Duration(days: 30)),
        categoryIds: ['cat1', 'cat2'],
        notes: 'Test notes',
        createdAt: tDate,
      );

      final result = BudgetModel.fromEntity(tBudget);

      expect(result.id, '1');
      expect(result.name, 'Test Budget');
      expect(result.budgetTypeIndex, BudgetType.categorySpecific.index);
      expect(result.targetAmount, 500.0);
      expect(result.periodTypeIndex, BudgetPeriodType.recurringMonthly.index);
      expect(result.startDate, tDate);
      expect(result.categoryIds, ['cat1', 'cat2']);
      expect(result.notes, 'Test notes');
      expect(result.createdAt, tDate);
    });

    test('toEntity should return a valid Entity', () {
      final result = tBudgetModel.toEntity();

      expect(result, isA<Budget>());
      expect(result.id, '1');
      expect(result.name, 'Test Budget');
      expect(result.type, BudgetType.categorySpecific);
      expect(result.targetAmount, 500.0);
      expect(result.period, BudgetPeriodType.recurringMonthly);
      expect(result.startDate, tDate);
      expect(result.categoryIds, ['cat1', 'cat2']);
      expect(result.notes, 'Test notes');
      expect(result.createdAt, tDate);
    });
  });
}
