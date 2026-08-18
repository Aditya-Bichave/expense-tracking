import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/hive_adapter_harness.dart';

/// Round-trips every persisted model through its generated Hive adapter.
///
/// These are the tests that catch the failure mode AGENTS.md warns about:
/// changing a HiveField id, dropping a field from `write` but not `read`, or
/// reordering fields. Any of those silently corrupts data on upgrade; here they
/// surface as a wrong value, a cast error, or an out-of-sync operation count.
void main() {
  final date = DateTime(2024, 3, 15, 9, 30);
  final later = DateTime(2024, 6, 1, 12);

  group('AssetAccountModelAdapter', () {
    final model = AssetAccountModel(
      id: 'a1',
      name: 'Everyday Checking',
      typeIndex: 2,
      initialBalance: 1234.56,
    );

    test('round-trips every field', () {
      final out = roundTrip(AssetAccountModelAdapter(), model);

      expect(out.id, 'a1');
      expect(out.name, 'Everyday Checking');
      expect(out.typeIndex, 2);
      expect(out.initialBalance, 1234.56);
    });

    test('writes a contiguous field index block matching the count', () {
      final adapter = AssetAccountModelAdapter();
      final indices = writtenFieldIndices(adapter, model);

      expect(indices, List.generate(indices.length, (i) => i));
      expect(declaredFieldCount(adapter, model), indices.length);
    });

    test('has a stable typeId', () {
      // Changing this breaks every existing box on disk.
      expect(AssetAccountModelAdapter().typeId, 1);
    });
  });

  group('BudgetModelAdapter', () {
    BudgetModel build({
      DateTime? startDate,
      DateTime? endDate,
      List<String>? categoryIds,
      String? notes,
    }) => BudgetModel(
      id: 'b1',
      name: 'Groceries',
      budgetTypeIndex: 1,
      targetAmount: 500,
      periodTypeIndex: 0,
      startDate: startDate,
      endDate: endDate,
      categoryIds: categoryIds,
      notes: notes,
      createdAt: date,
    );

    test('round-trips a fully populated budget', () {
      final out = roundTrip(
        BudgetModelAdapter(),
        build(
          startDate: date,
          endDate: later,
          categoryIds: ['c1', 'c2'],
          notes: 'monthly food',
        ),
      );

      expect(out.id, 'b1');
      expect(out.name, 'Groceries');
      expect(out.budgetTypeIndex, 1);
      expect(out.targetAmount, 500);
      expect(out.periodTypeIndex, 0);
      expect(out.startDate, date);
      expect(out.endDate, later);
      expect(out.categoryIds, ['c1', 'c2']);
      expect(out.notes, 'monthly food');
      expect(out.createdAt, date);
    });

    test('preserves nulls for every optional field', () {
      final out = roundTrip(BudgetModelAdapter(), build());

      expect(out.startDate, isNull);
      expect(out.endDate, isNull);
      expect(out.categoryIds, isNull);
      expect(out.notes, isNull);
    });

    test('an empty category list survives as an empty list, not null', () {
      final out = roundTrip(BudgetModelAdapter(), build(categoryIds: const []));

      expect(out.categoryIds, isEmpty);
      expect(out.categoryIds, isNotNull);
    });
  });

  group('CategoryModelAdapter', () {
    test('round-trips a category', () {
      final model = CategoryModel(
        id: 'c1',
        name: 'Food',
        iconName: 'restaurant',
        colorHex: '#FF0000',
        typeIndex: 0,
        isCustom: true,
        parentCategoryId: 'c-parent',
      );

      final out = roundTrip(CategoryModelAdapter(), model);

      expect(out.id, 'c1');
      expect(out.name, 'Food');
      expect(out.iconName, 'restaurant');
      expect(out.colorHex, '#FF0000');
      expect(out.typeIndex, 0);
      expect(out.isCustom, isTrue);
      expect(out.parentCategoryId, 'c-parent');
    });

    test('preserves a null parent category', () {
      final out = roundTrip(
        CategoryModelAdapter(),
        CategoryModel(
          id: 'c2',
          name: 'Travel',
          iconName: 'flight',
          colorHex: '#00FF00',
          typeIndex: 0,
          isCustom: false,
        ),
      );

      expect(out.parentCategoryId, isNull);
      expect(out.isCustom, isFalse);
    });
  });

  group('ExpenseModelAdapter', () {
    ExpenseModel build({
      String? categoryId,
      String? notes,
      List<ExpensePayer> payers = const [],
      List<ExpenseSplit> splits = const [],
    }) => ExpenseModel(
      id: 'e1',
      title: 'Dinner',
      amount: 84.25,
      date: date,
      categoryId: categoryId,
      accountId: 'a1',
      notes: notes,
      payers: payers,
      splits: splits,
    );

    test('round-trips the core fields', () {
      final out = roundTrip(
        ExpenseModelAdapter(),
        build(categoryId: 'c1', notes: 'with friends'),
      );

      expect(out.id, 'e1');
      expect(out.title, 'Dinner');
      expect(out.amount, 84.25);
      expect(out.date, date);
      expect(out.categoryId, 'c1');
      expect(out.accountId, 'a1');
      expect(out.notes, 'with friends');
    });

    test('does not persist payers or splits to the local box', () {
      // Split participation lives server-side; the local adapter deliberately
      // has no Hive field for it. Asserting that keeps the storage contract
      // explicit, so adding a field later is a conscious migration rather than
      // an accident.
      final out = roundTrip(
        ExpenseModelAdapter(),
        build(
          payers: const [ExpensePayer(userId: 'u1', amountPaid: 84.25)],
          splits: const [
            ExpenseSplit(
              userId: 'u1',
              shareType: SplitType.exact,
              shareValue: 42.13,
              computedAmount: 42.13,
            ),
          ],
        ),
      );

      expect(out.payers, isEmpty);
      expect(out.splits, isEmpty);
      // Everything else still survives the trip.
      expect(out.id, 'e1');
      expect(out.amount, 84.25);
    });

    test('defaults hold when optional fields are absent', () {
      final out = roundTrip(ExpenseModelAdapter(), build());

      expect(out.categoryId, isNull);
      expect(out.notes, isNull);
      expect(out.payers, isEmpty);
      expect(out.splits, isEmpty);
      expect(out.isRecurring, isFalse);
      expect(out.currency, 'USD');
    });
  });

  group('ExpensePayerModelAdapter / ExpenseSplitModelAdapter', () {
    test('payer round-trips', () {
      final out = roundTrip(
        ExpensePayerModelAdapter(),
        ExpensePayerModel(userId: 'u9', amount: 12.5),
      );

      expect(out.userId, 'u9');
      expect(out.amount, 12.5);
    });

    test('split round-trips including its split type', () {
      final out = roundTrip(
        ExpenseSplitModelAdapter(),
        ExpenseSplitModel(
          userId: 'u9',
          amount: 6.25,
          splitTypeValue: 'percent',
        ),
      );

      expect(out.userId, 'u9');
      expect(out.amount, 6.25);
      expect(out.splitTypeValue, 'percent');
    });
  });

  group('GoalModelAdapter', () {
    test('round-trips a goal with a target and achieved date', () {
      final out = roundTrip(
        GoalModelAdapter(),
        GoalModel(
          id: 'g1',
          name: 'New Laptop',
          targetAmount: 1500,
          targetDate: later,
          iconName: 'savings',
          description: 'for work',
          statusIndex: 1,
          totalSavedCache: 250.5,
          createdAt: date,
          achievedAt: later,
        ),
      );

      expect(out.id, 'g1');
      expect(out.name, 'New Laptop');
      expect(out.targetAmount, 1500);
      expect(out.targetDate, later);
      expect(out.iconName, 'savings');
      expect(out.description, 'for work');
      expect(out.statusIndex, 1);
      expect(out.totalSavedCache, 250.5);
      expect(out.createdAt, date);
      expect(out.achievedAt, later);
    });

    test('an unachieved goal keeps its nulls', () {
      final out = roundTrip(
        GoalModelAdapter(),
        GoalModel(
          id: 'g2',
          name: 'Boat',
          targetAmount: 9000,
          statusIndex: 0,
          totalSavedCache: 0,
          createdAt: date,
        ),
      );

      expect(out.targetDate, isNull);
      expect(out.achievedAt, isNull);
      expect(out.description, isNull);
    });
  });

  group('GoalContributionModelAdapter', () {
    test('round-trips a contribution', () {
      final out = roundTrip(
        GoalContributionModelAdapter(),
        GoalContributionModel(
          id: 'gc1',
          goalId: 'g1',
          amount: 75.25,
          date: date,
          note: 'bonus',
          createdAt: date,
        ),
      );

      expect(out.id, 'gc1');
      expect(out.goalId, 'g1');
      expect(out.amount, 75.25);
      expect(out.date, date);
      expect(out.note, 'bonus');
      expect(out.createdAt, date);
    });

    test('preserves a null note', () {
      final out = roundTrip(
        GoalContributionModelAdapter(),
        GoalContributionModel(
          id: 'gc2',
          goalId: 'g1',
          amount: 10,
          date: date,
          createdAt: date,
        ),
      );

      expect(out.note, isNull);
    });
  });

  group('GroupModelAdapter / GroupMemberModelAdapter', () {
    test('group round-trips', () {
      final out = roundTrip(
        GroupModelAdapter(),
        GroupModel(
          id: 'grp1',
          name: 'Weekend Trip',
          createdBy: 'u1',
          createdAt: date,
          updatedAt: later,
          typeValue: 'trip',
          currency: 'USD',
          photoUrl: 'https://example.com/p.png',
          isArchived: true,
        ),
      );

      expect(out.id, 'grp1');
      expect(out.name, 'Weekend Trip');
      expect(out.createdBy, 'u1');
      expect(out.createdAt, date);
      expect(out.updatedAt, later);
      expect(out.typeValue, 'trip');
      expect(out.currency, 'USD');
      expect(out.photoUrl, 'https://example.com/p.png');
      expect(out.isArchived, isTrue);
    });

    test('group without a photo keeps the null and the archived default', () {
      final out = roundTrip(
        GroupModelAdapter(),
        GroupModel(
          id: 'grp2',
          name: 'Flatmates',
          createdBy: 'u1',
          createdAt: date,
          updatedAt: date,
          typeValue: 'home',
          currency: 'INR',
        ),
      );

      expect(out.photoUrl, isNull);
      expect(out.isArchived, isFalse);
    });

    test('member round-trips', () {
      final out = roundTrip(
        GroupMemberModelAdapter(),
        GroupMemberModel(
          id: 'm1',
          groupId: 'grp1',
          userId: 'u2',
          roleValue: 'admin',
          joinedAt: date,
          updatedAt: later,
        ),
      );

      expect(out.id, 'm1');
      expect(out.groupId, 'grp1');
      expect(out.userId, 'u2');
      expect(out.roleValue, 'admin');
      expect(out.joinedAt, date);
      expect(out.updatedAt, later);
    });
  });

  group('GroupExpenseModelAdapter', () {
    test('round-trips a group expense with payers and splits', () {
      final out = roundTrip(
        GroupExpenseModelAdapter(),
        GroupExpenseModel(
          id: 'ge1',
          groupId: 'grp1',
          createdBy: 'u1',
          title: 'Taxi',
          amount: 30,
          currency: 'USD',
          occurredAt: date,
          createdAt: date,
          updatedAt: later,
          categoryId: 'c1',
          payers: [ExpensePayerModel(userId: 'u1', amount: 30)],
          splits: [
            ExpenseSplitModel(
              userId: 'u1',
              amount: 15,
              splitTypeValue: 'equal',
            ),
            ExpenseSplitModel(
              userId: 'u2',
              amount: 15,
              splitTypeValue: 'equal',
            ),
          ],
        ),
      );

      expect(out.id, 'ge1');
      expect(out.groupId, 'grp1');
      expect(out.title, 'Taxi');
      expect(out.amount, 30);
      expect(out.currency, 'USD');
      expect(out.occurredAt, date);
      expect(out.updatedAt, later);
      expect(out.categoryId, 'c1');
      expect(out.payers.single.amount, 30);
      expect(out.splits.map((s) => s.userId), ['u1', 'u2']);
    });

    test('an expense with no participants round-trips to empty lists', () {
      final out = roundTrip(
        GroupExpenseModelAdapter(),
        GroupExpenseModel(
          id: 'ge2',
          groupId: 'grp1',
          createdBy: 'u1',
          title: 'Coffee',
          amount: 4,
          currency: 'USD',
          occurredAt: date,
          createdAt: date,
          updatedAt: date,
        ),
      );

      expect(out.payers, isEmpty);
      expect(out.splits, isEmpty);
      expect(out.categoryId, isNull);
    });
  });

  group('IncomeModelAdapter', () {
    test('round-trips an income', () {
      final out = roundTrip(
        IncomeModelAdapter(),
        IncomeModel(
          id: 'i1',
          title: 'Salary',
          amount: 4200,
          date: date,
          categoryId: 'c-salary',
          accountId: 'a1',
          notes: 'March',
        ),
      );

      expect(out.id, 'i1');
      expect(out.title, 'Salary');
      expect(out.amount, 4200);
      expect(out.date, date);
      expect(out.categoryId, 'c-salary');
      expect(out.accountId, 'a1');
      expect(out.notes, 'March');
    });

    test('uncategorized income keeps its defaults', () {
      final out = roundTrip(
        IncomeModelAdapter(),
        IncomeModel(
          id: 'i2',
          title: 'Gift',
          amount: 50,
          date: date,
          accountId: 'a1',
        ),
      );

      expect(out.categoryId, isNull);
      expect(out.notes, isNull);
      expect(out.categorizationStatusValue, 'uncategorized');
      expect(out.isRecurring, isFalse);
    });
  });

  group('ProfileModelAdapter', () {
    test('round-trips a fully populated profile', () {
      final out = roundTrip(
        ProfileModelAdapter(),
        const ProfileModel(
          id: 'u1',
          fullName: 'Test Person',
          email: 'test@example.com',
          phone: '+10000000000',
          avatarUrl: 'https://example.com/a.png',
          currency: 'USD',
          timezone: 'UTC',
          upiId: 'test@upi',
        ),
      );

      expect(out.id, 'u1');
      expect(out.fullName, 'Test Person');
      expect(out.email, 'test@example.com');
      expect(out.phone, '+10000000000');
      expect(out.avatarUrl, 'https://example.com/a.png');
      expect(out.currency, 'USD');
      expect(out.timezone, 'UTC');
      expect(out.upiId, 'test@upi');
    });

    test('a sparse profile keeps every optional field null', () {
      final out = roundTrip(
        ProfileModelAdapter(),
        const ProfileModel(id: 'u2', currency: 'INR', timezone: 'Asia/Kolkata'),
      );

      expect(out.fullName, isNull);
      expect(out.email, isNull);
      expect(out.phone, isNull);
      expect(out.avatarUrl, isNull);
      expect(out.upiId, isNull);
    });
  });

  group('RecurringRuleModelAdapter', () {
    RecurringRuleModel build({
      int? dayOfWeek,
      int? dayOfMonth,
      DateTime? endDate,
      int? totalOccurrences,
      String? userId,
    }) => RecurringRuleModel(
      id: 'r1',
      userId: userId,
      amount: 1200,
      description: 'Rent',
      categoryId: 'c1',
      accountId: 'a1',
      transactionTypeIndex: 0,
      frequencyIndex: 2,
      interval: 1,
      startDate: date,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      endConditionTypeIndex: 0,
      endDate: endDate,
      totalOccurrences: totalOccurrences,
      statusIndex: 0,
      nextOccurrenceDate: later,
      occurrencesGenerated: 3,
    );

    test('round-trips a monthly rule', () {
      final out = roundTrip(
        RecurringRuleModelAdapter(),
        build(dayOfMonth: 5, userId: 'u1'),
      );

      expect(out.id, 'r1');
      expect(out.userId, 'u1');
      expect(out.amount, 1200);
      expect(out.description, 'Rent');
      expect(out.categoryId, 'c1');
      expect(out.accountId, 'a1');
      expect(out.transactionTypeIndex, 0);
      expect(out.frequencyIndex, 2);
      expect(out.interval, 1);
      expect(out.startDate, date);
      expect(out.dayOfMonth, 5);
      expect(out.nextOccurrenceDate, later);
      expect(out.occurrencesGenerated, 3);
    });

    test('round-trips a weekly rule bounded by an occurrence count', () {
      final out = roundTrip(
        RecurringRuleModelAdapter(),
        build(dayOfWeek: 3, totalOccurrences: 12),
      );

      expect(out.dayOfWeek, 3);
      expect(out.totalOccurrences, 12);
      expect(out.dayOfMonth, isNull);
      expect(out.endDate, isNull);
    });

    test('round-trips a rule bounded by an end date', () {
      final out = roundTrip(RecurringRuleModelAdapter(), build(endDate: later));

      expect(out.endDate, later);
      expect(out.totalOccurrences, isNull);
    });
  });

  group('RecurringRuleAuditLogModelAdapter', () {
    test('round-trips an audit entry', () {
      final out = roundTrip(
        RecurringRuleAuditLogModelAdapter(),
        RecurringRuleAuditLogModel(
          id: 'l1',
          ruleId: 'r1',
          timestamp: date,
          userId: 'u1',
          fieldChanged: 'amount',
          oldValue: '1200',
          newValue: '1300',
        ),
      );

      expect(out.id, 'l1');
      expect(out.ruleId, 'r1');
      expect(out.timestamp, date);
      expect(out.userId, 'u1');
      expect(out.fieldChanged, 'amount');
      expect(out.oldValue, '1200');
      expect(out.newValue, '1300');
    });
  });

  group('SettlementModelAdapter', () {
    test('round-trips a settlement', () {
      final out = roundTrip(
        SettlementModelAdapter(),
        SettlementModel(
          id: 's1',
          groupId: 'grp1',
          fromUserId: 'u1',
          toUserId: 'u2',
          amount: 42.5,
          currency: 'USD',
          createdAt: date,
        ),
      );

      expect(out.id, 's1');
      expect(out.groupId, 'grp1');
      expect(out.fromUserId, 'u1');
      expect(out.toUserId, 'u2');
      expect(out.amount, 42.5);
      expect(out.currency, 'USD');
      expect(out.createdAt, date);
    });
  });

  group('SyncMutationModelAdapter', () {
    test('round-trips a queued mutation', () {
      final out = roundTrip(
        SyncMutationModelAdapter(),
        SyncMutationModel(
          id: 'sm1',
          table: 'expenses',
          operation: OpType.create,
          payload: const {'id': 'e1', 'amount': 10},
          createdAt: date,
          retryCount: 2,
          status: SyncStatus.failed,
          lastError: 'network unreachable',
        ),
      );

      expect(out.id, 'sm1');
      expect(out.table, 'expenses');
      expect(out.operation, OpType.create);
      expect(out.payload, {'id': 'e1', 'amount': 10});
      expect(out.createdAt, date);
      expect(out.retryCount, 2);
      expect(out.status, SyncStatus.failed);
      expect(out.lastError, 'network unreachable');
    });

    test('a fresh mutation round-trips with its defaults', () {
      final out = roundTrip(
        SyncMutationModelAdapter(),
        SyncMutationModel(
          id: 'sm2',
          table: 'incomes',
          operation: OpType.delete,
          payload: const {},
          createdAt: date,
        ),
      );

      expect(out.retryCount, 0);
      expect(out.status, SyncStatus.pending);
      expect(out.lastError, isNull);
      expect(out.payload, isEmpty);
    });

    test('OpType and SyncStatus enums round-trip through their adapters', () {
      for (final op in OpType.values) {
        expect(roundTrip(OpTypeAdapter(), op), op);
      }
      for (final status in SyncStatus.values) {
        expect(roundTrip(SyncStatusAdapter(), status), status);
      }
    });
  });

  group('UserHistoryRuleModelAdapter', () {
    test('round-trips a learned categorization rule', () {
      final out = roundTrip(
        UserHistoryRuleModelAdapter(),
        UserHistoryRuleModel(
          ruleId: 'ur1',
          ruleType: 'merchant',
          matcher: 'starbucks',
          assignedCategoryId: 'c-coffee',
          timestamp: date,
        ),
      );

      expect(out.ruleId, 'ur1');
      expect(out.ruleType, 'merchant');
      expect(out.matcher, 'starbucks');
      expect(out.assignedCategoryId, 'c-coffee');
      expect(out.timestamp, date);
    });
  });

  group('adapter identity', () {
    test('every adapter declares a distinct typeId', () {
      final adapters = <dynamic>[
        AssetAccountModelAdapter(),
        BudgetModelAdapter(),
        CategoryModelAdapter(),
        ExpenseModelAdapter(),
        ExpensePayerModelAdapter(),
        ExpenseSplitModelAdapter(),
        GoalContributionModelAdapter(),
        GoalModelAdapter(),
        GroupExpenseModelAdapter(),
        GroupMemberModelAdapter(),
        GroupModelAdapter(),
        IncomeModelAdapter(),
        OpTypeAdapter(),
        ProfileModelAdapter(),
        RecurringRuleAuditLogModelAdapter(),
        RecurringRuleModelAdapter(),
        SettlementModelAdapter(),
        SyncMutationModelAdapter(),
        SyncStatusAdapter(),
        UserHistoryRuleModelAdapter(),
      ];

      final ids = adapters.map((a) => a.typeId as int).toList();

      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'duplicate Hive typeIds would make boxes unreadable',
      );
    });

    test('adapters of the same type compare equal and hash alike', () {
      expect(BudgetModelAdapter() == BudgetModelAdapter(), isTrue);
      expect(BudgetModelAdapter().hashCode, BudgetModelAdapter().hashCode);
      // Deliberately comparing unrelated adapter types: equality is by
      // typeId, so two different adapters must not compare equal.
      // ignore: unrelated_type_equality_checks
      expect(BudgetModelAdapter() == GoalModelAdapter(), isFalse);
    });
  });
}
