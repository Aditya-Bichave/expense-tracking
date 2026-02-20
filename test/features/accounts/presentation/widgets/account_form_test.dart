import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_form.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('AccountForm renders add mode correctly', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: Scaffold(body: AccountForm(onSubmit: (name, type, balance) {})),
    );

    expect(find.text('Add Account'), findsOneWidget); // Button label
    expect(find.text('Account Name'), findsOneWidget);
    expect(find.text('Initial Balance'), findsOneWidget);
  });

  testWidgets('AccountForm renders edit mode correctly', (
    WidgetTester tester,
  ) async {
    final account = AssetAccount(
      id: '1',
      name: 'My Bank',
      type: AssetType.bank,
      currentBalance: 500.0,
      initialBalance: 100.0,
    );

    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: Scaffold(
        body: AccountForm(
          initialAccount: account,
          currentBalanceForDisplay: 500.0,
          onSubmit: (name, type, balance) {},
        ),
      ),
    );

    expect(find.text('Update Account'), findsOneWidget);
    expect(find.text('My Bank'), findsOneWidget);
    expect(find.text('500.00'), findsOneWidget); // Current balance
    expect(find.text('Current Balance'), findsOneWidget);
  });

  testWidgets('AccountForm submits data', (WidgetTester tester) async {
    String? submittedName;
    AssetType? submittedType;
    double? submittedBalance;

    await pumpWidgetWithProviders(
      tester: tester,
      settingsState: const SettingsState(),
      widget: Scaffold(
        body: AccountForm(
          onSubmit: (name, type, balance) {
            submittedName = name;
            submittedType = type;
            submittedBalance = balance;
          },
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Account Name'),
      'New Account',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Initial Balance'),
      '200',
    );

    // Default type is Bank

    await tester.tap(find.text('Add Account'));
    await tester.pump();

    expect(submittedName, equals('New Account'));
    expect(submittedBalance, equals(200.0));
    expect(submittedType, equals(AssetType.bank));
  });
}
