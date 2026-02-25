import 'package:expense_tracker/core/data/demo_data.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:expense_tracker/core/utils/logger.dart';

/// Manages the demo mode state and in-memory demo data.
class DemoModeService {
  bool isDemoActive = false;

  // In-memory caches for demo data
  List<ExpenseModel> _demoExpenses = [];
  List<IncomeModel> _demoIncomes = [];
  List<AssetAccountModel> _demoAccounts = [];
  List<BudgetModel> _demoBudgets = [];
  List<GoalModel> _demoGoals = [];
  List<GoalContributionModel> _demoContributions = [];
  List<RecurringRuleModel> _demoRecurringRules = [];
  List<RecurringRuleAuditLogModel> _demoAuditLogs = [];

  // Singleton pattern
  static final DemoModeService _instance = DemoModeService._internal();
  factory DemoModeService() => _instance;
  DemoModeService._internal();

  /// Enters demo mode, loads static data into memory caches.
  void enterDemoMode() {
    log.info("[DemoModeService] Entering Demo Mode. Loading sample data.");
    isDemoActive = true;
    // Load copies of the static data
    _demoExpenses = List.from(DemoData.sampleExpenses);
    _demoIncomes = List.from(DemoData.sampleIncomes);
    _demoAccounts = List.from(DemoData.sampleAccounts);
    _demoBudgets = List.from(DemoData.sampleBudgets);
    _demoGoals = List.from(DemoData.sampleGoals);
    _demoContributions = List.from(DemoData.sampleContributions);
    _demoRecurringRules = List.from(DemoData.sampleRecurringRules);
    log.info("[DemoModeService] Sample data loaded into memory caches.");
  }

  /// Exits demo mode, clears memory caches.
  void exitDemoMode() {
    log.info("[DemoModeService] Exiting Demo Mode. Clearing caches.");
    isDemoActive = false;
    _demoExpenses = [];
    _demoIncomes = [];
    _demoAccounts = [];
    _demoBudgets = [];
    _demoGoals = [];
    _demoContributions = [];
    _demoRecurringRules = [];
    _demoAuditLogs = [];
  }

  // --- Expense Operations ---
  Future<List<ExpenseModel>> getDemoExpenses() async => _demoExpenses;
  Future<ExpenseModel?> getDemoExpenseById(String id) async =>
      _demoExpenses.where((e) => e.id == id).firstOrNull;
  Future<ExpenseModel> addDemoExpense(ExpenseModel expense) async {
    _demoExpenses.add(expense);
    return expense;
  }

  Future<ExpenseModel> updateDemoExpense(ExpenseModel expense) async {
    final index = _demoExpenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _demoExpenses[index] = expense;
      return expense;
    }
    // Should ideally not happen if called after a get, but handle defensively
    throw Exception("Demo Expense not found for update: ${expense.id}");
  }

  Future<void> deleteDemoExpense(String id) async {
    _demoExpenses.removeWhere((e) => e.id == id);
  }

  // --- Income Operations ---
  Future<List<IncomeModel>> getDemoIncomes() async => _demoIncomes;
  Future<IncomeModel?> getDemoIncomeById(String id) async =>
      _demoIncomes.where((i) => i.id == id).firstOrNull;
  Future<IncomeModel> addDemoIncome(IncomeModel income) async {
    _demoIncomes.add(income);
    return income;
  }

  Future<IncomeModel> updateDemoIncome(IncomeModel income) async {
    final index = _demoIncomes.indexWhere((i) => i.id == income.id);
    if (index != -1) {
      _demoIncomes[index] = income;
      return income;
    }
    throw Exception("Demo Income not found for update: ${income.id}");
  }

  Future<void> deleteDemoIncome(String id) async {
    _demoIncomes.removeWhere((i) => i.id == id);
  }

  // --- Account Operations ---
  Future<List<AssetAccountModel>> getDemoAccounts() async => _demoAccounts;
  Future<AssetAccountModel> addDemoAccount(AssetAccountModel account) async {
    _demoAccounts.add(account);
    return account;
  }

  Future<AssetAccountModel> updateDemoAccount(AssetAccountModel account) async {
    final index = _demoAccounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      _demoAccounts[index] = account;
      return account;
    }
    throw Exception("Demo Account not found for update: ${account.id}");
  }

  Future<void> deleteDemoAccount(String id) async {
    // Basic delete, doesn't check for transactions in demo
    _demoAccounts.removeWhere((a) => a.id == id);
  }

  // --- Budget Operations ---
  Future<List<BudgetModel>> getDemoBudgets() async => _demoBudgets;
  Future<BudgetModel?> getDemoBudgetById(String id) async =>
      _demoBudgets.where((b) => b.id == id).firstOrNull;
  Future<void> saveDemoBudget(BudgetModel budget) async {
    final index = _demoBudgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _demoBudgets[index] = budget; // Update
    } else {
      _demoBudgets.add(budget); // Add
    }
  }

  Future<void> deleteDemoBudget(String id) async {
    _demoBudgets.removeWhere((b) => b.id == id);
  }

  // --- Goal Operations ---
  Future<List<GoalModel>> getDemoGoals() async => _demoGoals;
  Future<GoalModel?> getDemoGoalById(String id) async =>
      _demoGoals.where((g) => g.id == id).firstOrNull;
  Future<void> saveDemoGoal(GoalModel goal) async {
    final index = _demoGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _demoGoals[index] = goal; // Update
    } else {
      _demoGoals.add(goal); // Add
    }
  }

  Future<void> deleteDemoGoal(String id) async {
    _demoGoals.removeWhere((g) => g.id == id);
  }

  // --- Goal Contribution Operations ---
  Future<List<GoalContributionModel>> getDemoContributionsForGoal(
    String goalId,
  ) async => _demoContributions.where((c) => c.goalId == goalId).toList();
  Future<List<GoalContributionModel>> getAllDemoContributions() async =>
      _demoContributions;
  Future<GoalContributionModel?> getDemoContributionById(String id) async =>
      _demoContributions.where((c) => c.id == id).firstOrNull;
  Future<void> saveDemoContribution(GoalContributionModel contribution) async {
    final index = _demoContributions.indexWhere((c) => c.id == contribution.id);
    if (index != -1) {
      _demoContributions[index] = contribution; // Update
    } else {
      _demoContributions.add(contribution); // Add
    }
  }

  Future<void> deleteDemoContribution(String id) async {
    _demoContributions.removeWhere((c) => c.id == id);
  }

  Future<void> deleteDemoContributions(List<String> ids) async {
    _demoContributions.removeWhere((c) => ids.contains(c.id));
  }

  // --- Recurring Rule Operations ---
  Future<List<RecurringRuleModel>> getDemoRecurringRules() async =>
      _demoRecurringRules;
  Future<RecurringRuleModel?> getDemoRecurringRuleById(String id) async =>
      _demoRecurringRules.where((r) => r.id == id).firstOrNull;
  Future<void> addDemoRecurringRule(RecurringRuleModel rule) async {
    _demoRecurringRules.add(rule);
  }

  Future<void> updateDemoRecurringRule(RecurringRuleModel rule) async {
    final index = _demoRecurringRules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _demoRecurringRules[index] = rule;
    }
  }

  Future<void> deleteDemoRecurringRule(String id) async {
    _demoRecurringRules.removeWhere((r) => r.id == id);
  }

  // --- Audit Logs ---
  Future<void> addDemoRecurringAuditLog(RecurringRuleAuditLogModel log) async {
    _demoAuditLogs.add(log);
  }

  Future<List<RecurringRuleAuditLogModel>> getDemoRecurringAuditLogsForRule(
    String ruleId,
  ) async => _demoAuditLogs.where((l) => l.ruleId == ruleId).toList();
}
