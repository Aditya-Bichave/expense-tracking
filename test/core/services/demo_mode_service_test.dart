import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoModeService demoModeService;

  setUp(() {
    demoModeService = DemoModeService();
    demoModeService.exitDemoMode(); // Reset state
  });

  tearDown(() {
    demoModeService.exitDemoMode();
  });

  test('initially isDemoActive is false', () {
    expect(demoModeService.isDemoActive, isFalse);
  });

  test('enterDemoMode sets isDemoActive to true and loads data', () async {
    demoModeService.enterDemoMode();

    expect(demoModeService.isDemoActive, isTrue);

    final expenses = await demoModeService.getDemoExpenses();
    expect(expenses, isNotEmpty);

    final incomes = await demoModeService.getDemoIncomes();
    expect(incomes, isNotEmpty);
  });

  test('exitDemoMode clears data and sets isDemoActive to false', () async {
    demoModeService.enterDemoMode();
    demoModeService.exitDemoMode();

    expect(demoModeService.isDemoActive, isFalse);

    final expenses = await demoModeService.getDemoExpenses();
    expect(expenses, isEmpty);
  });

  test('addDemoExpense adds expense to memory cache', () async {
    demoModeService.enterDemoMode();
    final initialCount = (await demoModeService.getDemoExpenses()).length;

    final newExpense = ExpenseModel(
      id: 'test_id',
      amount: 100,
      date: DateTime.now(),
      categoryId: 'cat_id',
      accountId: 'acc_id',
      title: 'Test Expense',
    );

    await demoModeService.addDemoExpense(newExpense);

    final expenses = await demoModeService.getDemoExpenses();
    expect(expenses.length, equals(initialCount + 1));
    expect(expenses.last.id, equals('test_id'));
  });

  test('updateDemoExpense updates existing expense', () async {
    demoModeService.enterDemoMode();
    final expenses = await demoModeService.getDemoExpenses();
    final originalExpense = expenses.first;

    final updatedExpense = ExpenseModel(
      id: originalExpense.id,
      amount: 999.99, // Updated amount
      date: originalExpense.date,
      categoryId: originalExpense.categoryId,
      accountId: originalExpense.accountId,
      title: originalExpense.title,
      categorizationStatusValue: originalExpense.categorizationStatusValue,
      confidenceScoreValue: originalExpense.confidenceScoreValue,
      isRecurring: originalExpense.isRecurring,
      merchantId: originalExpense.merchantId,
    );

    await demoModeService.updateDemoExpense(updatedExpense);

    final fetchedExpense = await demoModeService.getDemoExpenseById(
      originalExpense.id,
    );
    expect(fetchedExpense?.amount, equals(999.99));
  });

  test('deleteDemoExpense removes expense', () async {
    demoModeService.enterDemoMode();
    final expenses = await demoModeService.getDemoExpenses();
    final idToDelete = expenses.first.id;
    final initialCount = expenses.length;

    await demoModeService.deleteDemoExpense(idToDelete);

    final newExpenses = await demoModeService.getDemoExpenses();
    expect(newExpenses.length, equals(initialCount - 1));
    expect(newExpenses.where((e) => e.id == idToDelete), isEmpty);
  });
}
