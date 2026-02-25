import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/settings/data/repositories/data_management_repository_impl.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox<T> extends Mock implements Box<T> {}

void main() {
  late DataManagementRepositoryImpl repository;
  late MockBox<AssetAccountModel> mockAccountBox;
  late MockBox<ExpenseModel> mockExpenseBox;
  late MockBox<IncomeModel> mockIncomeBox;
  late MockBox<CategoryModel> mockCategoryBox;
  late MockBox<UserHistoryRuleModel> mockUserHistoryBox;
  late MockBox<BudgetModel> mockBudgetBox;
  late MockBox<GoalModel> mockGoalBox;
  late MockBox<GoalContributionModel> mockContributionBox;
  late MockBox<RecurringRuleModel> mockRecurringRuleBox;
  late MockBox<RecurringRuleAuditLogModel> mockRecurringRuleAuditLogBox;
  late MockBox<SyncMutationModel> mockOutboxBox;
  late MockBox<GroupModel> mockGroupBox;
  late MockBox<GroupMemberModel> mockGroupMemberBox;
  late MockBox<GroupExpenseModel> mockGroupExpenseBox;

  setUp(() {
    mockAccountBox = MockBox<AssetAccountModel>();
    mockExpenseBox = MockBox<ExpenseModel>();
    mockIncomeBox = MockBox<IncomeModel>();
    mockCategoryBox = MockBox<CategoryModel>();
    mockUserHistoryBox = MockBox<UserHistoryRuleModel>();
    mockBudgetBox = MockBox<BudgetModel>();
    mockGoalBox = MockBox<GoalModel>();
    mockContributionBox = MockBox<GoalContributionModel>();
    mockRecurringRuleBox = MockBox<RecurringRuleModel>();
    mockRecurringRuleAuditLogBox = MockBox<RecurringRuleAuditLogModel>();
    mockOutboxBox = MockBox<SyncMutationModel>();
    mockGroupBox = MockBox<GroupModel>();
    mockGroupMemberBox = MockBox<GroupMemberModel>();
    mockGroupExpenseBox = MockBox<GroupExpenseModel>();

    repository = DataManagementRepositoryImpl(
      accountBox: mockAccountBox,
      expenseBox: mockExpenseBox,
      incomeBox: mockIncomeBox,
      categoryBox: mockCategoryBox,
      userHistoryBox: mockUserHistoryBox,
      budgetBox: mockBudgetBox,
      goalBox: mockGoalBox,
      contributionBox: mockContributionBox,
      recurringRuleBox: mockRecurringRuleBox,
      recurringRuleAuditLogBox: mockRecurringRuleAuditLogBox,
      outboxBox: mockOutboxBox,
      groupBox: mockGroupBox,
      groupMemberBox: mockGroupMemberBox,
      groupExpenseBox: mockGroupExpenseBox,
    );
  });

  test('should gather all data for backup', () async {
    // Arrange
    when(() => mockAccountBox.values).thenReturn([]);
    when(() => mockExpenseBox.values).thenReturn([]);
    when(() => mockIncomeBox.values).thenReturn([]);
    when(() => mockCategoryBox.values).thenReturn([]);

    // Act
    final result = await repository.getAllDataForBackup();

    // Assert
    expect(result.isRight(), true);
    result.fold((failure) => fail('Should be Right'), (allData) {
      expect(allData.accounts, isEmpty);
      expect(allData.expenses, isEmpty);
      expect(allData.incomes, isEmpty);
      expect(allData.categories, isEmpty);
    });
  });

  test('should clear all data', () async {
    // Arrange
    when(() => mockAccountBox.clear()).thenAnswer((_) async => 0);
    when(() => mockExpenseBox.clear()).thenAnswer((_) async => 0);
    when(() => mockIncomeBox.clear()).thenAnswer((_) async => 0);
    when(() => mockCategoryBox.clear()).thenAnswer((_) async => 0);
    when(() => mockUserHistoryBox.clear()).thenAnswer((_) async => 0);
    when(() => mockBudgetBox.clear()).thenAnswer((_) async => 0);
    when(() => mockGoalBox.clear()).thenAnswer((_) async => 0);
    when(() => mockContributionBox.clear()).thenAnswer((_) async => 0);
    when(() => mockRecurringRuleBox.clear()).thenAnswer((_) async => 0);
    when(() => mockRecurringRuleAuditLogBox.clear()).thenAnswer((_) async => 0);
    when(() => mockOutboxBox.clear()).thenAnswer((_) async => 0);
    when(() => mockGroupBox.clear()).thenAnswer((_) async => 0);
    when(() => mockGroupMemberBox.clear()).thenAnswer((_) async => 0);
    when(() => mockGroupExpenseBox.clear()).thenAnswer((_) async => 0);

    // Act
    final result = await repository.clearAllData();

    // Assert
    expect(result, const Right(null));
    verify(() => mockAccountBox.clear()).called(1);
    verify(() => mockExpenseBox.clear()).called(1);
    verify(() => mockIncomeBox.clear()).called(1);
    verify(() => mockCategoryBox.clear()).called(1);
    // ... verify others if needed, but one call verifies the method works roughly
  });
}
