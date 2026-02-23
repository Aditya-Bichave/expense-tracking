import 'package:expense_tracker/core/di/service_configurations/groups_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/income_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/profile_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/recurring_transactions_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/report_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/settings_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/sync_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/transactions_dependencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dependencies configuration classes exist and have register method', () {
    // We check if the static method exists by referencing it.
    // Calling them might require GetIt setup which is brittle in unit test without full mock.
    // Just verifying they are importable and have the method is a basic structure test.

    expect(GroupsDependencies.register, isA<Function>());
    expect(IncomeDependencies.register, isA<Function>());
    expect(ProfileDependencies.register, isA<Function>());
    expect(RecurringTransactionsDependencies.register, isA<Function>());
    expect(ReportDependencies.register, isA<Function>());
    expect(SettingsDependencies.register, isA<Function>());
    expect(SyncDependencies.register, isA<Function>());
    expect(TransactionsDependencies.register, isA<Function>());
  });
}
