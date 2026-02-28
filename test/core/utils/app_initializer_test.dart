import 'dart:io';
import 'package:expense_tracker/core/utils/app_initializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'initHiveBoxes registers adapters and opens all expected boxes',
    () async {
      // 16-byte key for HiveAesCipher
      final encryptionKey = List<int>.generate(32, (i) => i % 256);

      // Call the initializer
      final boxes = await AppInitializer.initHiveBoxes(encryptionKey);

      // Verify that the boxes are open
      expect(boxes.profileBox.isOpen, isTrue);
      expect(boxes.expenseBox.isOpen, isTrue);
      expect(boxes.accountBox.isOpen, isTrue);
      expect(boxes.incomeBox.isOpen, isTrue);
      expect(boxes.categoryBox.isOpen, isTrue);
      expect(boxes.userHistoryBox.isOpen, isTrue);
      expect(boxes.budgetBox.isOpen, isTrue);
      expect(boxes.goalBox.isOpen, isTrue);
      expect(boxes.contributionBox.isOpen, isTrue);
      expect(boxes.recurringRuleBox.isOpen, isTrue);
      expect(boxes.recurringRuleAuditLogBox.isOpen, isTrue);
      expect(boxes.outboxBox.isOpen, isTrue);
      expect(boxes.groupBox.isOpen, isTrue);
      expect(boxes.groupMemberBox.isOpen, isTrue);
      expect(boxes.groupExpenseBox.isOpen, isTrue);

      // Verify a few adapters are registered
      expect(Hive.isAdapterRegistered(ProfileModelAdapter().typeId), isTrue);
      expect(Hive.isAdapterRegistered(ExpenseModelAdapter().typeId), isTrue);
    },
  );
}
