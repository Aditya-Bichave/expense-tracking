import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('appName is correct', () {
      expect(AppConstants.appName, 'Spend Savvy');
    });

    test('defaultAppLockEnabled is false', () {
      expect(AppConstants.defaultAppLockEnabled, false);
    });

    test('backup metadata keys are correct', () {
      expect(AppConstants.backupMetaKey, 'metadata');
      expect(AppConstants.backupDataKey, 'data');
      expect(AppConstants.backupVersionKey, 'appVersion');
      expect(AppConstants.backupTimestampKey, 'backupTimestamp');
      expect(AppConstants.backupFormatVersionKey, 'formatVersion');
    });

    test('backup format version is correct', () {
      expect(AppConstants.backupFormatVersion, '1.0');
    });

    test('backup data keys are correct', () {
      expect(AppConstants.backupAccountsKey, 'accounts');
      expect(AppConstants.backupExpensesKey, 'expenses');
      expect(AppConstants.backupIncomesKey, 'incomes');
    });

    test('all string constants are non-empty', () {
      expect(AppConstants.appName.isNotEmpty, true);
      expect(AppConstants.backupMetaKey.isNotEmpty, true);
      expect(AppConstants.backupDataKey.isNotEmpty, true);
      expect(AppConstants.backupVersionKey.isNotEmpty, true);
      expect(AppConstants.backupTimestampKey.isNotEmpty, true);
      expect(AppConstants.backupFormatVersionKey.isNotEmpty, true);
      expect(AppConstants.backupFormatVersion.isNotEmpty, true);
      expect(AppConstants.backupAccountsKey.isNotEmpty, true);
      expect(AppConstants.backupExpensesKey.isNotEmpty, true);
      expect(AppConstants.backupIncomesKey.isNotEmpty, true);
    });
  });
}