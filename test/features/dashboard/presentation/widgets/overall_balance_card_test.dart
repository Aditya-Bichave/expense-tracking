import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/overall_balance_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockFinancialOverview extends Mock implements FinancialOverview {}

void main() {
  late MockFinancialOverview mockOverview;

  setUp(() {
    mockOverview = MockFinancialOverview();
  });

  Widget buildTestWidget() {
    return OverallBalanceCard(overview: mockOverview);
  }

  group('OverallBalanceCard', () {
    testWidgets('renders balance and net flow correctly', (tester) async {
      when(() => mockOverview.overallBalance).thenReturn(1234.56);
      when(() => mockOverview.netFlow).thenReturn(-78.90);

      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: buildTestWidget(),
      );

      expect(find.text('\$1,234.56'), findsOneWidget);
      expect(find.text('-\$78.90'), findsOneWidget);
    });

    testWidgets('shows primary color for positive or zero balance', (tester) async {
      when(() => mockOverview.overallBalance).thenReturn(100.0);
      when(() => mockOverview.netFlow).thenReturn(0.0);

      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: buildTestWidget(),
      );

      final balanceText = tester.widget<Text>(find.text('\$100.00'));
      final theme = Theme.of(tester.element(find.byType(OverallBalanceCard)));

      expect(balanceText.style?.color, theme.colorScheme.primary);
    });

    testWidgets('shows error color for negative balance', (tester) async {
      when(() => mockOverview.overallBalance).thenReturn(-50.0);
      when(() => mockOverview.netFlow).thenReturn(0.0);

      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(selectedCountryCode: 'US'),
        widget: buildTestWidget(),
      );

      final balanceText = tester.widget<Text>(find.text('-\$50.00'));
      final theme = Theme.of(tester.element(find.byType(OverallBalanceCard)));

      expect(balanceText.style?.color, theme.colorScheme.error);
    });
  });
}
