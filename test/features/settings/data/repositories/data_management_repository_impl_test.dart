import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
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

// The repository only ever reads `.id` off these and hands the object to
// putAll, so a minimal fake keeps the fixtures readable.
class _FakeAccount extends Fake implements AssetAccountModel {
  _FakeAccount(this.id);
  @override
  final String id;
}

class _FakeExpense extends Fake implements ExpenseModel {
  _FakeExpense(this.id);
  @override
  final String id;
}

class _FakeIncome extends Fake implements IncomeModel {
  _FakeIncome(this.id);
  @override
  final String id;
}

class _FakeCategory extends Fake implements CategoryModel {
  _FakeCategory(this.id);
  @override
  final String id;
}

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

  /// Every clear must be stubbed: the repository fires all fourteen through a
  /// single Future.wait, so one unstubbed box fails the whole call.
  List<MockBox<dynamic>> allBoxes() => [
    mockAccountBox,
    mockExpenseBox,
    mockIncomeBox,
    mockCategoryBox,
    mockUserHistoryBox,
    mockBudgetBox,
    mockGoalBox,
    mockContributionBox,
    mockRecurringRuleBox,
    mockRecurringRuleAuditLogBox,
    mockOutboxBox,
    mockGroupBox,
    mockGroupMemberBox,
    mockGroupExpenseBox,
  ];

  void stubClears() {
    for (final box in allBoxes()) {
      when(box.clear).thenAnswer((_) async => 0);
    }
  }

  void stubPutAlls() {
    when(() => mockAccountBox.putAll(any())).thenAnswer((_) async {});
    when(() => mockExpenseBox.putAll(any())).thenAnswer((_) async {});
    when(() => mockIncomeBox.putAll(any())).thenAnswer((_) async {});
    when(() => mockCategoryBox.putAll(any())).thenAnswer((_) async {});
  }

  AllData sampleData() => AllData(
    accounts: [_FakeAccount('a1')],
    expenses: [_FakeExpense('e1')],
    incomes: [_FakeIncome('i1')],
    categories: [_FakeCategory('c1')],
  );

  group('clearAllData', () {
    test('clears every box, not just the four backed-up ones', () async {
      stubClears();

      expect(await repository.clearAllData(), const Right<Failure, void>(null));

      for (final box in allBoxes()) {
        verify(box.clear).called(1);
      }
    });

    test('a failing box surfaces as ClearDataFailure', () async {
      stubClears();
      when(() => mockGoalBox.clear()).thenThrow(HiveError('box is closed'));

      final result = await repository.clearAllData();

      expect(
        result.fold((f) => f, (_) => null),
        isA<ClearDataFailure>().having(
          (f) => f.message,
          'message',
          contains('Failed to clear data'),
        ),
      );
    });
  });

  group('restoreData', () {
    test('clears before writing, and keys each box by id', () async {
      stubClears();
      stubPutAlls();

      final result = await repository.restoreData(sampleData());

      expect(result.isRight(), isTrue);
      // Ordering matters: writing before the clear would merge the backup into
      // the existing data instead of replacing it.
      final ordered = verifyInOrder([
        () => mockAccountBox.clear(),
        () => mockAccountBox.putAll(captureAny()),
      ]);
      final accounts = ordered[1].captured.single as Map<dynamic, dynamic>;
      expect(accounts.keys, ['a1']);
      final categories =
          verify(() => mockCategoryBox.putAll(captureAny())).captured.single
              as Map<dynamic, dynamic>;
      expect(categories.keys, ['c1']);
    });

    test(
      'a failed clear aborts the restore before anything is written',
      () async {
        stubClears();
        stubPutAlls();
        when(() => mockOutboxBox.clear()).thenThrow(HiveError('locked'));

        final result = await repository.restoreData(sampleData());

        // The propagated failure is the clear's, not a generic restore error —
        // otherwise the real cause is lost.
        expect(result.fold((f) => f, (_) => null), isA<ClearDataFailure>());
        verifyNever(() => mockAccountBox.putAll(any()));
        verifyNever(() => mockExpenseBox.putAll(any()));
      },
    );

    test('a failing write surfaces as RestoreFailure', () async {
      stubClears();
      stubPutAlls();
      when(
        () => mockExpenseBox.putAll(any()),
      ).thenThrow(HiveError('disk full'));

      final result = await repository.restoreData(sampleData());

      expect(
        result.fold((f) => f, (_) => null),
        isA<RestoreFailure>().having(
          (f) => f.message,
          'message',
          contains('Failed to restore data'),
        ),
      );
    });

    test('an empty backup still clears the existing data', () async {
      stubClears();
      stubPutAlls();

      final result = await repository.restoreData(
        AllData(accounts: [], expenses: [], incomes: [], categories: []),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockAccountBox.clear()).called(1);
      final accounts =
          verify(() => mockAccountBox.putAll(captureAny())).captured.single
              as Map<dynamic, dynamic>;
      expect(accounts, isEmpty);
    });
  });

  group('getAllDataForBackup', () {
    test('a box read failure surfaces as CacheFailure', () async {
      when(() => mockAccountBox.values).thenThrow(HiveError('box is closed'));

      final result = await repository.getAllDataForBackup();

      expect(
        result.fold((f) => f, (_) => null),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          contains('Failed to retrieve data for backup'),
        ),
      );
    });

    test('carries every row through from the boxes', () async {
      when(() => mockAccountBox.values).thenReturn([_FakeAccount('a1')]);
      when(() => mockExpenseBox.values).thenReturn([_FakeExpense('e1')]);
      when(() => mockIncomeBox.values).thenReturn([_FakeIncome('i1')]);
      when(() => mockCategoryBox.values).thenReturn([_FakeCategory('c1')]);

      final result = await repository.getAllDataForBackup();

      final data = result.fold((f) => fail('expected data'), (d) => d);
      expect(data.accounts.single.id, 'a1');
      expect(data.expenses.single.id, 'e1');
      expect(data.incomes.single.id, 'i1');
      expect(data.categories.single.id, 'c1');
    });
  });
}
