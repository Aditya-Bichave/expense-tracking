import 'package:expense_tracker/core/data/demo_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DemoData', () {
    test('sampleAccounts is not empty', () {
      expect(DemoData.sampleAccounts, isNotEmpty);
      for (final account in DemoData.sampleAccounts) {
        expect(account.id, isNotEmpty);
        expect(account.name, isNotEmpty);
      }
    });

    test('sampleExpenses is not empty', () {
      expect(DemoData.sampleExpenses, isNotEmpty);
      for (final expense in DemoData.sampleExpenses) {
        expect(expense.id, isNotEmpty);
        expect(expense.title, isNotEmpty);
        // categoryId can be null for uncategorized
      }
    });

    test('sampleIncomes is not empty', () {
      expect(DemoData.sampleIncomes, isNotEmpty);
      for (final income in DemoData.sampleIncomes) {
        expect(income.id, isNotEmpty);
        expect(income.title, isNotEmpty);
      }
    });

    test('sampleBudgets is not empty', () {
      expect(DemoData.sampleBudgets, isNotEmpty);
      for (final budget in DemoData.sampleBudgets) {
        expect(budget.id, isNotEmpty);
        expect(budget.name, isNotEmpty);
      }
    });

    test('sampleGoals is not empty', () {
      expect(DemoData.sampleGoals, isNotEmpty);
      for (final goal in DemoData.sampleGoals) {
        expect(goal.id, isNotEmpty);
        expect(goal.name, isNotEmpty);
      }
    });

    test('sampleContributions is not empty', () {
      expect(DemoData.sampleContributions, isNotEmpty);
      for (final contribution in DemoData.sampleContributions) {
        expect(contribution.id, isNotEmpty);
        expect(contribution.goalId, isNotEmpty);
      }
    });

    test('Category IDs are constant', () {
      expect(DemoData.catGroceriesId, 'groceries');
      expect(DemoData.catDiningId, 'food');
      expect(DemoData.catUncategorizedId, 'uncategorized');
    });
  });
}
