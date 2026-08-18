import 'package:expense_tracker/core/data/demo_data.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // DemoModeService is a singleton, so every test must start from a clean
  // slate or state leaks across the file.
  late DemoModeService service;

  final fixedDate = DateTime(2024, 1, 15);

  ExpenseModel expense(String id, {double amount = 10}) => ExpenseModel(
    id: id,
    title: 'Expense $id',
    amount: amount,
    date: fixedDate,
    accountId: 'a1',
  );

  IncomeModel incomeModel(String id, {double amount = 100}) => IncomeModel(
    id: id,
    title: 'Income $id',
    amount: amount,
    date: fixedDate,
    accountId: 'a1',
  );

  AssetAccountModel accountModel(String id, {String name = 'Bank'}) =>
      AssetAccountModel(id: id, name: name, typeIndex: 0, initialBalance: 100);

  BudgetModel budgetModel(String id, {double target = 500}) => BudgetModel(
    id: id,
    name: 'Budget $id',
    budgetTypeIndex: 0,
    targetAmount: target,
    periodTypeIndex: 0,
    createdAt: fixedDate,
  );

  GoalModel goalModel(String id, {double target = 1000}) => GoalModel(
    id: id,
    name: 'Goal $id',
    targetAmount: target,
    statusIndex: 0,
    totalSavedCache: 0,
    createdAt: fixedDate,
  );

  GoalContributionModel contribution(String id, String goalId) =>
      GoalContributionModel(
        id: id,
        goalId: goalId,
        amount: 25,
        date: fixedDate,
        createdAt: fixedDate,
      );

  RecurringRuleModel rule(String id, {double amount = 50}) =>
      RecurringRuleModel(
        id: id,
        amount: amount,
        description: 'Rule $id',
        categoryId: 'c1',
        accountId: 'a1',
        transactionTypeIndex: 0,
        frequencyIndex: 0,
        interval: 1,
        startDate: fixedDate,
        endConditionTypeIndex: 0,
        statusIndex: 0,
        nextOccurrenceDate: fixedDate,
        occurrencesGenerated: 0,
      );

  RecurringRuleAuditLogModel auditLog(String id, String ruleId) =>
      RecurringRuleAuditLogModel(
        id: id,
        ruleId: ruleId,
        timestamp: fixedDate,
        userId: 'u1',
        fieldChanged: 'amount',
        oldValue: '50',
        newValue: '60',
      );

  setUp(() {
    service = DemoModeService();
    service.exitDemoMode();
  });

  tearDown(() {
    service.exitDemoMode();
  });

  group('lifecycle', () {
    test('is a singleton', () {
      expect(identical(DemoModeService(), DemoModeService()), isTrue);
    });

    test('starts inactive with empty caches', () async {
      expect(service.isDemoActive, isFalse);
      expect(await service.getDemoExpenses(), isEmpty);
      expect(await service.getDemoAccounts(), isEmpty);
    });

    test('entering demo mode loads the sample dataset', () async {
      service.enterDemoMode();

      expect(service.isDemoActive, isTrue);
      expect(
        await service.getDemoExpenses(),
        hasLength(DemoData.sampleExpenses.length),
      );
      expect(
        await service.getDemoIncomes(),
        hasLength(DemoData.sampleIncomes.length),
      );
      expect(
        await service.getDemoAccounts(),
        hasLength(DemoData.sampleAccounts.length),
      );
      expect(
        await service.getDemoBudgets(),
        hasLength(DemoData.sampleBudgets.length),
      );
      expect(
        await service.getDemoGoals(),
        hasLength(DemoData.sampleGoals.length),
      );
      expect(
        await service.getDemoRecurringRules(),
        hasLength(DemoData.sampleRecurringRules.length),
      );
    });

    test('demo caches are copies, so edits do not mutate DemoData', () async {
      service.enterDemoMode();
      final originalCount = DemoData.sampleExpenses.length;

      await service.addDemoExpense(expense('injected'));

      expect(DemoData.sampleExpenses, hasLength(originalCount));
      expect(await service.getDemoExpenses(), hasLength(originalCount + 1));
    });

    test('exiting demo mode clears every cache', () async {
      service.enterDemoMode();
      await service.addDemoRecurringAuditLog(auditLog('l1', 'r1'));

      service.exitDemoMode();

      expect(service.isDemoActive, isFalse);
      expect(await service.getDemoExpenses(), isEmpty);
      expect(await service.getDemoIncomes(), isEmpty);
      expect(await service.getDemoAccounts(), isEmpty);
      expect(await service.getDemoBudgets(), isEmpty);
      expect(await service.getDemoGoals(), isEmpty);
      expect(await service.getAllDemoContributions(), isEmpty);
      expect(await service.getDemoRecurringRules(), isEmpty);
      expect(await service.getDemoRecurringAuditLogsForRule('r1'), isEmpty);
    });
  });

  group('expenses', () {
    test('add then read back by id', () async {
      await service.addDemoExpense(expense('e1', amount: 42));

      expect((await service.getDemoExpenseById('e1'))?.amount, 42);
    });

    test('lookup of an unknown id returns null', () async {
      expect(await service.getDemoExpenseById('ghost'), isNull);
    });

    test('update replaces the stored expense in place', () async {
      await service.addDemoExpense(expense('e1', amount: 10));

      final updated = await service.updateDemoExpense(
        expense('e1', amount: 99),
      );

      expect(updated.amount, 99);
      expect((await service.getDemoExpenseById('e1'))?.amount, 99);
      expect(await service.getDemoExpenses(), hasLength(1));
    });

    test('update of a missing expense throws', () async {
      expect(
        () => service.updateDemoExpense(expense('missing')),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Demo Expense not found'),
          ),
        ),
      );
    });

    test('delete removes only the targeted expense', () async {
      await service.addDemoExpense(expense('e1'));
      await service.addDemoExpense(expense('e2'));

      await service.deleteDemoExpense('e1');

      final remaining = await service.getDemoExpenses();
      expect(remaining.map((e) => e.id), ['e2']);
    });
  });

  group('incomes', () {
    test('add then read back by id', () async {
      await service.addDemoIncome(incomeModel('i1', amount: 500));

      expect((await service.getDemoIncomeById('i1'))?.amount, 500);
    });

    test('update replaces the stored income', () async {
      await service.addDemoIncome(incomeModel('i1', amount: 100));

      final updated = await service.updateDemoIncome(
        incomeModel('i1', amount: 250),
      );

      expect(updated.amount, 250);
      expect((await service.getDemoIncomeById('i1'))?.amount, 250);
    });

    test('update of a missing income throws', () async {
      expect(
        () => service.updateDemoIncome(incomeModel('missing')),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Demo Income not found'),
          ),
        ),
      );
    });

    test('delete removes the income', () async {
      await service.addDemoIncome(incomeModel('i1'));

      await service.deleteDemoIncome('i1');

      expect(await service.getDemoIncomes(), isEmpty);
    });
  });

  group('accounts', () {
    test('add then list', () async {
      await service.addDemoAccount(accountModel('a1', name: 'Wallet'));

      expect((await service.getDemoAccounts()).single.name, 'Wallet');
    });

    test('update replaces the stored account', () async {
      await service.addDemoAccount(accountModel('a1', name: 'Wallet'));

      final updated = await service.updateDemoAccount(
        accountModel('a1', name: 'Renamed'),
      );

      expect(updated.name, 'Renamed');
      expect((await service.getDemoAccounts()).single.name, 'Renamed');
    });

    test('update of a missing account throws', () async {
      expect(
        () => service.updateDemoAccount(accountModel('missing')),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Demo Account not found'),
          ),
        ),
      );
    });

    test('delete removes the account', () async {
      await service.addDemoAccount(accountModel('a1'));

      await service.deleteDemoAccount('a1');

      expect(await service.getDemoAccounts(), isEmpty);
    });
  });

  group('budgets', () {
    test('save inserts when the id is new', () async {
      await service.saveDemoBudget(budgetModel('b1'));

      expect(await service.getDemoBudgets(), hasLength(1));
    });

    test('save updates in place when the id already exists', () async {
      await service.saveDemoBudget(budgetModel('b1', target: 100));
      await service.saveDemoBudget(budgetModel('b1', target: 900));

      expect(await service.getDemoBudgets(), hasLength(1));
      expect((await service.getDemoBudgetById('b1'))?.targetAmount, 900);
    });

    test('lookup of an unknown budget returns null', () async {
      expect(await service.getDemoBudgetById('ghost'), isNull);
    });

    test('delete removes the budget', () async {
      await service.saveDemoBudget(budgetModel('b1'));

      await service.deleteDemoBudget('b1');

      expect(await service.getDemoBudgets(), isEmpty);
    });
  });

  group('goals', () {
    test('save inserts then updates by id', () async {
      await service.saveDemoGoal(goalModel('g1', target: 1000));
      await service.saveDemoGoal(goalModel('g1', target: 2000));

      expect(await service.getDemoGoals(), hasLength(1));
      expect((await service.getDemoGoalById('g1'))?.targetAmount, 2000);
    });

    test('lookup of an unknown goal returns null', () async {
      expect(await service.getDemoGoalById('ghost'), isNull);
    });

    test('delete removes the goal', () async {
      await service.saveDemoGoal(goalModel('g1'));

      await service.deleteDemoGoal('g1');

      expect(await service.getDemoGoals(), isEmpty);
    });
  });

  group('goal contributions', () {
    test('filters contributions by goal id', () async {
      await service.saveDemoContribution(contribution('c1', 'g1'));
      await service.saveDemoContribution(contribution('c2', 'g2'));
      await service.saveDemoContribution(contribution('c3', 'g1'));

      final forG1 = await service.getDemoContributionsForGoal('g1');

      expect(forG1.map((c) => c.id), ['c1', 'c3']);
      expect(await service.getAllDemoContributions(), hasLength(3));
    });

    test(
      'save updates an existing contribution rather than duplicating',
      () async {
        await service.saveDemoContribution(contribution('c1', 'g1'));
        await service.saveDemoContribution(contribution('c1', 'g1'));

        expect(await service.getAllDemoContributions(), hasLength(1));
      },
    );

    test('lookup of an unknown contribution returns null', () async {
      expect(await service.getDemoContributionById('ghost'), isNull);
    });

    test('delete removes one contribution', () async {
      await service.saveDemoContribution(contribution('c1', 'g1'));

      await service.deleteDemoContribution('c1');

      expect(await service.getAllDemoContributions(), isEmpty);
    });

    test('bulk delete removes every listed contribution', () async {
      await service.saveDemoContribution(contribution('c1', 'g1'));
      await service.saveDemoContribution(contribution('c2', 'g1'));
      await service.saveDemoContribution(contribution('c3', 'g1'));

      await service.deleteDemoContributions(['c1', 'c3']);

      expect((await service.getAllDemoContributions()).map((c) => c.id), [
        'c2',
      ]);
    });
  });

  group('recurring rules', () {
    test('add then read back by id', () async {
      await service.addDemoRecurringRule(rule('r1', amount: 75));

      expect((await service.getDemoRecurringRuleById('r1'))?.amount, 75);
    });

    test('lookup of an unknown rule returns null', () async {
      expect(await service.getDemoRecurringRuleById('ghost'), isNull);
    });

    test('update replaces the stored rule', () async {
      await service.addDemoRecurringRule(rule('r1', amount: 50));

      await service.updateDemoRecurringRule(rule('r1', amount: 65));

      expect((await service.getDemoRecurringRuleById('r1'))?.amount, 65);
    });

    test('updating a missing rule is a no-op rather than an error', () async {
      await service.updateDemoRecurringRule(rule('ghost'));

      expect(await service.getDemoRecurringRules(), isEmpty);
    });

    test('delete removes the rule', () async {
      await service.addDemoRecurringRule(rule('r1'));

      await service.deleteDemoRecurringRule('r1');

      expect(await service.getDemoRecurringRules(), isEmpty);
    });
  });

  group('audit logs', () {
    test('filters audit logs by rule id', () async {
      await service.addDemoRecurringAuditLog(auditLog('l1', 'r1'));
      await service.addDemoRecurringAuditLog(auditLog('l2', 'r2'));
      await service.addDemoRecurringAuditLog(auditLog('l3', 'r1'));

      final forR1 = await service.getDemoRecurringAuditLogsForRule('r1');

      expect(forR1.map((l) => l.id), ['l1', 'l3']);
    });

    test('an unknown rule id yields no logs', () async {
      await service.addDemoRecurringAuditLog(auditLog('l1', 'r1'));

      expect(await service.getDemoRecurringAuditLogsForRule('other'), isEmpty);
    });
  });
}
