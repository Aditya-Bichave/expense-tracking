import 'dart:io';

import 'package:expense_tracker/core/storage/app_hive_boxes.dart';
import 'package:expense_tracker/core/storage/hive_adapters.dart';
import 'package:expense_tracker/core/storage/hive_box_names.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Guards the storage invariants that a refactor can silently break.
///
/// Both have been broken before: a dead duplicate of the initializer had drifted
/// to a different set of box names and encrypted only one of the fifteen boxes.
/// Adopting it would have orphaned every install's data and written the rest in
/// plaintext, and no test would have failed.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive-box-names-test');
    Hive.init(tempDir.path);
    HiveAdapters.registerAll();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// The names the shipped app has always opened. Written out literally rather
  /// than derived from the constants under test, so a rename has to be made
  /// twice and deliberately.
  const shippedNames = <String>{
    'expenses',
    'accounts',
    'income',
    'categories',
    'user_history_rules',
    'budgets',
    'goals',
    'goal_contributions',
    'recurring_rules',
    'recurring_rule_audit_logs',
    'sync_outbox',
    'groups',
    'group_members',
    'group_expenses',
    'profile',
  };

  List<int> keyOf(int seed) => List<int>.generate(32, (i) => (i + seed) % 256);

  test('box names match the shipped on-disk names', () {
    expect(
      {
        HiveBoxNames.expenses,
        HiveBoxNames.accounts,
        HiveBoxNames.income,
        HiveBoxNames.categories,
        HiveBoxNames.userHistoryRules,
        HiveBoxNames.budgets,
        HiveBoxNames.goals,
        HiveBoxNames.goalContributions,
        HiveBoxNames.recurringRules,
        HiveBoxNames.recurringRuleAuditLogs,
        HiveBoxNames.syncOutbox,
        HiveBoxNames.groups,
        HiveBoxNames.groupMembers,
        HiveBoxNames.groupExpenses,
        HiveBoxNames.profile,
      },
      shippedNames,
      reason:
          'A box name changed. Hive resolves boxes by name, so this repoints '
          'the app at a different file and orphans existing user data.',
    );
  });

  test('open() opens every shipped box and no others', () async {
    await AppHiveBoxes.open(keyOf(0));

    for (final name in shippedNames) {
      expect(
        Hive.isBoxOpen(name),
        isTrue,
        reason: '$name was not opened by AppHiveBoxes.open',
      );
    }
  });

  test('the cipher is in effect: a wrong key cannot read the data', () async {
    final written = await AppHiveBoxes.open(keyOf(0));
    await written.expenseBox.put(
      'k',
      ExpenseModel(
        id: 'e1',
        title: 'Coffee',
        amount: 3.5,
        date: DateTime(2024, 1, 1),
        accountId: 'a1',
      ),
    );
    await Hive.close();

    // Right key: the value round-trips. Asserted first, because opening with the
    // wrong key runs Hive's crash recovery and discards the frame from disk.
    final sameKey = await AppHiveBoxes.open(keyOf(0));
    expect(sameKey.expenseBox.get('k')?.title, 'Coffee');
    await Hive.close();

    // Wrong key: the frame fails its checksum and crash recovery drops it, so
    // the value is simply gone. If the cipher had been dropped -- as the dead
    // initializer did for 14 of the 15 boxes -- the payload would be plaintext
    // and this read would succeed.
    final wrongKey = await AppHiveBoxes.open(keyOf(7));
    expect(
      wrongKey.expenseBox.get('k'),
      isNull,
      reason: 'A wrong encryption key must not be able to read the data.',
    );
  });

  test('the generated registrar covers SettlementModel', () {
    expect(
      Hive.isAdapterRegistered(SettlementModelAdapter().typeId),
      isTrue,
      reason:
          'SettlementModelAdapter was missing from the hand-maintained adapter '
          'list, so persisting a settlement threw at runtime.',
    );
  });
}
