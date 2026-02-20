import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  final testAccount = AssetAccount(
    id: '1',
    name: 'Test Account',
    type: AssetType.bank,
    currentBalance: 100.0,
  );

  testWidgets('AccountSelectorDropdown renders correctly with accounts', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      accountListState: AccountListLoaded(accounts: [testAccount]),
      widget: Scaffold(body: AccountSelectorDropdown(onChanged: (val) {})),
    );

    expect(find.text('Select Account'), findsOneWidget); // Default hint
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

    // Open dropdown to see items
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Test Account'), findsOneWidget);
  });

  testWidgets('AccountSelectorDropdown shows loading indicator', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settle: false, // Don't settle because CircularProgressIndicator spins
      accountListState: const AccountListLoading(),
      widget: Scaffold(body: AccountSelectorDropdown(onChanged: (val) {})),
    );

    // Pump a frame to let widget build
    await tester.pump();

    // Verify loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AccountSelectorDropdown shows error', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      accountListState: const AccountListError('Error loading'),
      widget: Scaffold(body: AccountSelectorDropdown(onChanged: (val) {})),
    );

    expect(find.text('Error loading accounts: Error loading'), findsOneWidget);
  });
}
