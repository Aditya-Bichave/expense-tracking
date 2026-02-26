// ignore_for_file: directives_ordering

import 'package:expense_tracker/core/data/demo_data.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoModeService service;

  setUp(() {
    service = DemoModeService();
    service.exitDemoMode(); // Ensure clean state
  });

  tearDown(() {
    service.exitDemoMode();
  });

  group('DemoModeService', () {
    test('initially isDemoActive is false', () {
      expect(service.isDemoActive, false);
    });

    test('enterDemoMode sets isDemoActive to true and loads data', () async {
      service.enterDemoMode();
      expect(service.isDemoActive, true);

      final expenses = await service.getDemoExpenses();
      // DemoData.sampleExpenses should be loaded
      expect(expenses.length, DemoData.sampleExpenses.length);
    });

    test('exitDemoMode clears data and sets isDemoActive to false', () async {
      service.enterDemoMode();
      service.exitDemoMode();

      expect(service.isDemoActive, false);
      final expenses = await service.getDemoExpenses();
      expect(expenses, isEmpty);
    });

    test('addDemoExpense adds expense to memory cache', () async {
      service.enterDemoMode();
      final initialCount = (await service.getDemoExpenses()).length;

      final newExpense = ExpenseModel(
        id: 'new-1',
        title: 'Test',
        amount: 10.0,
        date: DateTime.now(),
        accountId: 'acc-1',
      );

      await service.addDemoExpense(newExpense);
      final expenses = await service.getDemoExpenses();

      expect(expenses.length, initialCount + 1);
      expect(expenses.last.id, 'new-1');
    });

    test('updateDemoExpense updates existing expense', () async {
      service.enterDemoMode();
      final original = (await service.getDemoExpenses()).first;

      final updated = ExpenseModel(
        id: original.id,
        title: 'Updated Title',
        amount: 999.0,
        date: original.date,
        accountId: original.accountId,
      );

      await service.updateDemoExpense(updated);
      final result = await service.getDemoExpenseById(original.id);

      expect(result?.title, 'Updated Title');
      expect(result?.amount, 999.0);
    });

    test('deleteDemoExpense removes expense', () async {
      service.enterDemoMode();
      final original = (await service.getDemoExpenses()).first;

      await service.deleteDemoExpense(original.id);
      final result = await service.getDemoExpenseById(original.id);

      expect(result, isNull);
    });
  });
}
