import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
// import 'package:expense_tracker/features/categories/domain/entities/category.dart'; // Don't need the full import if only using the ID string
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart'; // Import Status enum
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:uuid/uuid.dart';

/// Contains static sample data for Demo Mode.
class DemoData {
  static final _uuid = Uuid();

  // --- Sample Accounts ---
  static final AssetAccountModel checkingAccount = AssetAccountModel(
    id: _uuid.v4(),
    name: 'Main Checking',
    typeIndex: AssetType.bank.index,
    initialBalance: 1250.75,
  );
  static final AssetAccountModel savingsAccount = AssetAccountModel(
    id: _uuid.v4(),
    name: 'Rainy Day Fund',
    typeIndex: AssetType.bank.index,
    initialBalance: 5300.00,
  );
  static final AssetAccountModel cashWallet = AssetAccountModel(
    id: _uuid.v4(),
    name: 'Cash Wallet',
    typeIndex: AssetType.cash.index,
    initialBalance: 85.50,
  );

  static final List<AssetAccountModel> sampleAccounts = [
    // Made final
    checkingAccount,
    savingsAccount,
    cashWallet,
  ];

  // --- Sample Category IDs (Ensure these align with your predefined IDs) ---
  // Using const for IDs is better practice
  static const String catGroceriesId = 'groceries';
  static const String catDiningId = 'food';
  static const String catTransportId = 'transport';
  static const String catBillsId = 'utilities';
  static const String catEntertainmentId = 'entertainment';
  static const String catShoppingId = 'shopping';
  static const String catSalaryId = 'salary';
  static const String catFreelanceId = 'freelance';
  static const String catRentId = 'rent';
  static const String catSubscriptionsId = 'subscription';
  static const String catOtherId = 'other';
  // --- FIXED: Use string literal directly ---
  static const String catUncategorizedId = 'uncategorized';
  // --- END FIX ---

  // --- Sample Expenses ---
  static final List<ExpenseModel> sampleExpenses = [
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Grocery Run',
      amount: 75.40,
      date: DateTime.now().subtract(const Duration(days: 2)),
      categoryId: catGroceriesId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Lunch with Friends',
      amount: 42.00,
      date: DateTime.now().subtract(const Duration(days: 3)),
      categoryId: catDiningId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Gas Refill',
      amount: 55.10,
      date: DateTime.now().subtract(const Duration(days: 4)),
      categoryId: catTransportId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Electricity Bill',
      amount: 89.90,
      date: DateTime.now().subtract(const Duration(days: 5)),
      categoryId: catBillsId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Movie Tickets',
      amount: 28.00,
      date: DateTime.now().subtract(const Duration(days: 7)),
      categoryId: catEntertainmentId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Coffee',
      amount: 5.25,
      date: DateTime.now().subtract(const Duration(days: 8)),
      categoryId:
          catDiningId, // Keep suggested category ID even if needs review
      accountId: cashWallet.id,
      categorizationStatusValue: CategorizationStatus.needsReview.value,
      confidenceScoreValue: 0.7,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'New T-Shirt',
      amount: 35.00,
      date: DateTime.now().subtract(const Duration(days: 10)),
      categoryId: catShoppingId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Weekly Groceries',
      amount: 98.60,
      date: DateTime.now().subtract(const Duration(days: 9)),
      categoryId: catGroceriesId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Bus Fare',
      amount: 2.75,
      date: DateTime.now().subtract(const Duration(days: 11)),
      categoryId: catTransportId,
      accountId: cashWallet.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Streaming Service',
      amount: 14.99,
      date: DateTime.now().subtract(const Duration(days: 15)),
      categoryId: catSubscriptionsId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Dinner Takeout',
      amount: 31.50,
      date: DateTime.now().subtract(const Duration(days: 18)),
      categoryId: catDiningId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Rent Payment',
      amount: 850.00,
      date: DateTime.now().subtract(const Duration(days: 30)),
      categoryId: catRentId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'More Groceries',
      amount: 62.30,
      date: DateTime.now().subtract(const Duration(days: 22)),
      categoryId: catGroceriesId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Parking Fee',
      amount: 12.00,
      date: DateTime.now().subtract(const Duration(days: 25)),
      categoryId: catTransportId,
      accountId: cashWallet.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    ExpenseModel(
      id: _uuid.v4(),
      title: 'Book Purchase',
      amount: 19.95,
      date: DateTime.now().subtract(const Duration(days: 28)),
      // For uncategorized, categoryId should be null
      categoryId: null, // Explicitly null
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.uncategorized.value,
      confidenceScoreValue: null,
    ),
  ];

  // --- Sample Incomes ---
  static final List<IncomeModel> sampleIncomes = [
    IncomeModel(
      id: _uuid.v4(),
      title: 'Paycheck',
      amount: 2500.00,
      date: DateTime.now().subtract(const Duration(days: 6)),
      categoryId: catSalaryId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    IncomeModel(
      id: _uuid.v4(),
      title: 'Freelance Project',
      amount: 450.00,
      date: DateTime.now().subtract(const Duration(days: 12)),
      categoryId: catFreelanceId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    IncomeModel(
      id: _uuid.v4(),
      title: 'Paycheck',
      amount: 2500.00,
      date: DateTime.now().subtract(const Duration(days: 20)),
      categoryId: catSalaryId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
    IncomeModel(
      id: _uuid.v4(),
      title: 'Sold Item Online',
      amount: 50.00,
      date: DateTime.now().subtract(const Duration(days: 26)),
      categoryId: catOtherId,
      accountId: checkingAccount.id,
      categorizationStatusValue: CategorizationStatus.categorized.value,
      confidenceScoreValue: 1.0,
    ),
  ];

  // --- Sample Budgets ---
  static final BudgetModel overallBudget = BudgetModel(
      id: _uuid.v4(),
      name: 'Overall Monthly Spending',
      budgetTypeIndex: BudgetType.overall.index,
      targetAmount: 1500.00,
      periodTypeIndex: BudgetPeriodType.recurringMonthly.index,
      createdAt: DateTime.now().subtract(const Duration(days: 40)));

  static final BudgetModel diningBudget = BudgetModel(
      id: _uuid.v4(),
      name: 'Dining Out',
      budgetTypeIndex: BudgetType.categorySpecific.index,
      targetAmount: 200.00,
      periodTypeIndex: BudgetPeriodType.recurringMonthly.index,
      categoryIds: [catDiningId],
      createdAt: DateTime.now().subtract(const Duration(days: 45)));

  static final BudgetModel groceriesBudget = BudgetModel(
      id: _uuid.v4(),
      name: 'Groceries',
      budgetTypeIndex: BudgetType.categorySpecific.index,
      targetAmount: 400.00,
      periodTypeIndex: BudgetPeriodType.recurringMonthly.index,
      categoryIds: [catGroceriesId],
      createdAt: DateTime.now().subtract(const Duration(days: 50)));

  static final List<BudgetModel> sampleBudgets = [
    // Made final
    overallBudget,
    diningBudget,
    groceriesBudget,
  ];

  // --- Sample Goals ---
  static final GoalModel vacationGoal = GoalModel(
      id: _uuid.v4(),
      name: 'Hawaii Trip Fund',
      targetAmount: 3000.00,
      targetDate: DateTime.now().add(const Duration(days: 180)),
      iconName: 'flight_takeoff',
      description: 'Saving for a 1 week trip!',
      statusIndex: GoalStatus.active.index,
      totalSavedCache: 1200.00, // Initial cache (contributions sum up to this)
      createdAt: DateTime.now().subtract(const Duration(days: 60)));

  static final GoalModel laptopGoal = GoalModel(
      id: _uuid.v4(),
      name: 'New Laptop',
      targetAmount: 1500.00,
      targetDate: DateTime.now().add(const Duration(days: 90)),
      iconName: 'computer',
      statusIndex: GoalStatus.active.index,
      totalSavedCache: 550.00, // Initial cache (contributions sum up to this)
      createdAt: DateTime.now().subtract(const Duration(days: 30)));

  static final List<GoalModel> sampleGoals = [
    // Made final
    vacationGoal,
    laptopGoal,
  ];

  // --- Sample Contributions ---
  static final List<GoalContributionModel> sampleContributions = [
    // Made final
    // Vacation Goal
    GoalContributionModel(
        id: _uuid.v4(),
        goalId: vacationGoal.id,
        amount: 500.00,
        date: DateTime.now().subtract(const Duration(days: 55)),
        createdAt: DateTime.now().subtract(const Duration(days: 55))),
    GoalContributionModel(
        id: _uuid.v4(),
        goalId: vacationGoal.id,
        amount: 400.00,
        date: DateTime.now().subtract(const Duration(days: 25)),
        note: 'Tax Refund',
        createdAt: DateTime.now().subtract(const Duration(days: 25))),
    GoalContributionModel(
        id: _uuid.v4(),
        goalId: vacationGoal.id,
        amount: 300.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 5))),
    // Laptop Goal
    GoalContributionModel(
        id: _uuid.v4(),
        goalId: laptopGoal.id,
        amount: 200.00,
        date: DateTime.now().subtract(const Duration(days: 28)),
        createdAt: DateTime.now().subtract(const Duration(days: 28))),
    GoalContributionModel(
        id: _uuid.v4(),
        goalId: laptopGoal.id,
        amount: 350.00,
        date: DateTime.now().subtract(const Duration(days: 10)),
        note: 'Sold old device',
        createdAt: DateTime.now().subtract(const Duration(days: 10))),
  ];
}
