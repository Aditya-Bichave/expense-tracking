import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockOnTap extends Mock {
  void call();
}

void main() {
  final mockAccountPositive = AssetAccount(
    id: '1',
    name: 'Main Bank',
    balance: 1500.75,
    type: AccountType.bank,
  );
  final mockAccountNegative = AssetAccount(
    id: '2',
    name: 'Credit Card',
    balance: -300.50,
    type: AccountType.bank,
  );

  group('AccountCard', () {
    testWidgets('renders account name, type, and balance', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: AccountCard(account: mockAccountPositive),
      );

      expect(find.text('Main Bank'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('\$1,500.75'), findsOneWidget);
    });

    testWidgets('balance color is primary for positive balance', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AccountCard(account: mockAccountPositive),
      );

      final balanceText = tester.widget<Text>(find.textContaining('\$'));
      final theme = Theme.of(tester.element(find.byType(AccountCard)));

      expect(balanceText.style?.color, theme.colorScheme.primary);
    });

    testWidgets('balance color is error for negative balance', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AccountCard(account: mockAccountNegative),
      );

      final balanceText = tester.widget<Text>(find.textContaining('\$'));
      final theme = Theme.of(tester.element(find.byType(AccountCard)));

      expect(balanceText.style?.color, theme.colorScheme.error);
    });

    testWidgets('onTap callback is called when tapped', (tester) async {
      final mockOnTap = MockOnTap();
      when(() => mockOnTap.call()).thenAnswer((_) {});

      await pumpWidgetWithProviders(
        tester: tester,
        widget: AccountCard(account: mockAccountPositive, onTap: mockOnTap.call),
      );

      await tester.tap(find.byType(AppCard));

      verify(() => mockOnTap.call()).called(1);
    });
  });
}
