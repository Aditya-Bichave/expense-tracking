import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';

void main() {
  group('RouteNames', () {
    group('main routes', () {
      test('initialSetup route is correct', () {
        expect(RouteNames.initialSetup, '/setup');
      });

      test('login route is correct', () {
        expect(RouteNames.login, '/login');
      });

      test('verifyOtp route is correct', () {
        expect(RouteNames.verifyOtp, '/verify-otp');
      });

      test('dashboard route is correct', () {
        expect(RouteNames.dashboard, '/dashboard');
      });

      test('transactionsList route is correct', () {
        expect(RouteNames.transactionsList, '/transactions');
      });

      test('budgetsAndCats route is correct', () {
        expect(RouteNames.budgetsAndCats, '/plan');
      });

      test('accounts route is correct', () {
        expect(RouteNames.accounts, '/accounts');
      });

      test('settings route is correct', () {
        expect(RouteNames.settings, '/settings');
      });

      test('recurring route is correct', () {
        expect(RouteNames.recurring, '/recurring');
      });

      test('groups route is correct', () {
        expect(RouteNames.groups, '/groups');
      });
    });

    group('sub routes', () {
      test('groupDetail is correct', () {
        expect(RouteNames.groupDetail, 'group_detail');
      });

      test('addRecurring is correct', () {
        expect(RouteNames.addRecurring, 'add_recurring');
      });

      test('editRecurring is correct', () {
        expect(RouteNames.editRecurring, 'edit_recurring');
      });

      test('addTransaction is correct', () {
        expect(RouteNames.addTransaction, 'add');
      });

      test('editTransaction is correct', () {
        expect(RouteNames.editTransaction, 'edit');
      });

      test('transactionDetail is correct', () {
        expect(RouteNames.transactionDetail, 'transaction_detail');
      });

      test('addBudget is correct', () {
        expect(RouteNames.addBudget, 'add_budget');
      });

      test('editBudget is correct', () {
        expect(RouteNames.editBudget, 'edit_budget');
      });

      test('budgetDetail is correct', () {
        expect(RouteNames.budgetDetail, 'budget_detail');
      });

      test('manageCategories is correct', () {
        expect(RouteNames.manageCategories, 'manage_categories');
      });

      test('addCategory is correct', () {
        expect(RouteNames.addCategory, 'add_category');
      });

      test('editCategory is correct', () {
        expect(RouteNames.editCategory, 'edit_category');
      });

      test('addGoal is correct', () {
        expect(RouteNames.addGoal, 'add_goal');
      });

      test('editGoal is correct', () {
        expect(RouteNames.editGoal, 'edit_goal');
      });

      test('goalDetail is correct', () {
        expect(RouteNames.goalDetail, 'goal_detail');
      });

      test('addAccount is correct', () {
        expect(RouteNames.addAccount, 'add_account');
      });

      test('editAccount is correct', () {
        expect(RouteNames.editAccount, 'edit_account');
      });

      test('accountDetail is correct', () {
        expect(RouteNames.accountDetail, 'account_detail');
      });

      test('addLiabilityAccount is correct', () {
        expect(RouteNames.addLiabilityAccount, 'add_liability_account');
      });

      test('settingsExport is correct', () {
        expect(RouteNames.settingsExport, 'settings_export');
      });
    });

    group('report routes', () {
      test('reportSpendingCategory is correct', () {
        expect(RouteNames.reportSpendingCategory, 'spending_category');
      });

      test('reportSpendingTime is correct', () {
        expect(RouteNames.reportSpendingTime, 'spending_time');
      });

      test('reportIncomeExpense is correct', () {
        expect(RouteNames.reportIncomeExpense, 'income_expense');
      });

      test('reportBudgetPerformance is correct', () {
        expect(RouteNames.reportBudgetPerformance, 'budget_performance');
      });

      test('reportGoalProgress is correct', () {
        expect(RouteNames.reportGoalProgress, 'goal_progress');
      });
    });

    group('parameter names', () {
      test('paramId is correct', () {
        expect(RouteNames.paramId, 'id');
      });

      test('paramAccountId is correct', () {
        expect(RouteNames.paramAccountId, 'accountId');
      });

      test('paramTransactionId is correct', () {
        expect(RouteNames.paramTransactionId, 'transactionId');
      });

      test('paramBudgetId is correct', () {
        expect(RouteNames.paramBudgetId, 'budgetId');
      });

      test('paramGoalId is correct', () {
        expect(RouteNames.paramGoalId, 'goalId');
      });
    });

    test('all route names are non-empty', () {
      expect(RouteNames.initialSetup.isNotEmpty, true);
      expect(RouteNames.login.isNotEmpty, true);
      expect(RouteNames.dashboard.isNotEmpty, true);
      expect(RouteNames.addTransaction.isNotEmpty, true);
    });

    test('main routes start with /', () {
      expect(RouteNames.initialSetup.startsWith('/'), true);
      expect(RouteNames.login.startsWith('/'), true);
      expect(RouteNames.dashboard.startsWith('/'), true);
      expect(RouteNames.transactionsList.startsWith('/'), true);
    });

    test('sub routes do not start with /', () {
      expect(RouteNames.addTransaction.startsWith('/'), false);
      expect(RouteNames.editTransaction.startsWith('/'), false);
      expect(RouteNames.groupDetail.startsWith('/'), false);
    });
  });
}