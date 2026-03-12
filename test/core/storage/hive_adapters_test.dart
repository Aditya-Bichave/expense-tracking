import 'dart:io';

import 'package:expense_tracker/core/storage/hive_adapters.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive-adapters-test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'registerAll registers critical sync and group expense adapters idempotently',
    () {
      HiveAdapters.registerAll();
      HiveAdapters.registerAll();

      expect(
        Hive.isAdapterRegistered(SyncMutationModelAdapter().typeId),
        isTrue,
      );
      expect(Hive.isAdapterRegistered(OpTypeAdapter().typeId), isTrue);
      expect(Hive.isAdapterRegistered(SyncStatusAdapter().typeId), isTrue);
      expect(
        Hive.isAdapterRegistered(GroupExpenseModelAdapter().typeId),
        isTrue,
      );
      expect(
        Hive.isAdapterRegistered(ExpensePayerModelAdapter().typeId),
        isTrue,
      );
      expect(
        Hive.isAdapterRegistered(ExpenseSplitModelAdapter().typeId),
        isTrue,
      );
    },
  );
}
