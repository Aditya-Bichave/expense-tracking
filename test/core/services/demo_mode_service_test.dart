import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoModeService service;

  setUp(() {
    service = DemoModeService();
    // Ensure we start fresh
    service.exitDemoMode();
  });

  group('DemoModeService', () {
    test('singleton returns same instance', () {
      final s1 = DemoModeService();
      final s2 = DemoModeService();
      expect(s1, same(s2));
    });

    test('enterDemoMode loads sample data', () async {
      expect(service.isDemoActive, isFalse);

      service.enterDemoMode();

      expect(service.isDemoActive, isTrue);
      expect((await service.getDemoExpenses()).isNotEmpty, isTrue);
      expect((await service.getDemoIncomes()).isNotEmpty, isTrue);
      expect((await service.getDemoAccounts()).isNotEmpty, isTrue);
      expect((await service.getDemoBudgets()).isNotEmpty, isTrue);
      expect((await service.getDemoGoals()).isNotEmpty, isTrue);
    });

    test('exitDemoMode clears sample data', () async {
      service.enterDemoMode();
      service.exitDemoMode();

      expect(service.isDemoActive, isFalse);
      expect((await service.getDemoExpenses()).isEmpty, isTrue);
      expect((await service.getDemoIncomes()).isEmpty, isTrue);
      expect((await service.getDemoAccounts()).isEmpty, isTrue);
      expect((await service.getDemoBudgets()).isEmpty, isTrue);
      expect((await service.getDemoGoals()).isEmpty, isTrue);
    });

    group('Expense Operations', () {
      setUp(() {
        service.enterDemoMode();
      });

      test('addDemoExpense adds expense', () async {
        final initialCount = (await service.getDemoExpenses()).length;
        final newExpense = ExpenseModel(
          id: 'new-1',
          title: 'New Expense',
          amount: 100,
          date: DateTime.now(),
          categoryId: 'c1',
          accountId: 'a1',
        );

        await service.addDemoExpense(newExpense);

        final expenses = await service.getDemoExpenses();
        expect(expenses.length, initialCount + 1);
        expect(expenses.contains(newExpense), isTrue);
      });

      test('getDemoExpenseById returns expense', () async {
        final expenses = await service.getDemoExpenses();
        final first = expenses.first;

        final result = await service.getDemoExpenseById(first.id);
        expect(result, equals(first));
      });

      test('updateDemoExpense updates expense', () async {
        final expenses = await service.getDemoExpenses();
        final first = expenses.first;

        final updated = ExpenseModel(
          id: first.id,
          title: first.title,
          amount: 999.0,
          date: first.date,
          categoryId: first.categoryId,
          accountId: first.accountId,
          isRecurring: first.isRecurring,
        );

        await service.updateDemoExpense(updated);

        final result = await service.getDemoExpenseById(first.id);
        expect(result?.amount, 999.0);
      });

      test('deleteDemoExpense removes expense', () async {
        final expenses = await service.getDemoExpenses();
        final first = expenses.first;

        await service.deleteDemoExpense(first.id);

        final result = await service.getDemoExpenseById(first.id);
        expect(result, isNull);
      });
    });

    // Similar groups for other entities could be added, but Expense coverage proves the pattern.
  });
}
