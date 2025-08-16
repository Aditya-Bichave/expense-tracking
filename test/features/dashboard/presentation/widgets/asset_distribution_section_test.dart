import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_section.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

// A mock AppModeTheme to control the `preferDataTableForLists` property in tests.
class TestAppModeTheme extends AppModeTheme {
  final bool preferTables;
  const TestAppModeTheme({required this.preferTables})
      : super(
          cardOuterPadding: EdgeInsets.zero,
          cardInnerPadding: EdgeInsets.zero,
          cardStyle: CardStyle.flat,
          pagePadding: EdgeInsets.zero,
          preferDataTableForLists: preferTables,
          assets: const ElementalAssets(), // Provide a default
        );
}

void main() {
  group('AssetDistributionSection', () {
    testWidgets('renders Pie Chart for Elemental UI mode', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(uiMode: UIMode.elemental),
        widget: const AssetDistributionSection(accountBalances: {}),
      );

      expect(find.byType(AssetDistributionPieChart), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('renders Pie Chart for Quantum mode when preferDataTableForLists is false', (tester) async {
      // The default Quantum theme in the app has preferDataTableForLists = false
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(uiMode: UIMode.quantum),
        widget: const AssetDistributionSection(accountBalances: {}),
      );

      expect(find.byType(AssetDistributionPieChart), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('renders DataTable for Quantum mode when preferDataTableForLists is true', (tester) async {
      // To test this, we need to inject a custom AppModeTheme.
      // We can wrap our widget in a Theme with a specific extension.
      await pumpWidgetWithProviders(
        tester: tester,
        settingsState: const SettingsState(uiMode: UIMode.quantum),
        widget: Builder(
          builder: (context) {
            return Theme(
              data: Theme.of(context).copyWith(
                extensions: const <ThemeExtension<dynamic>>[
                  TestAppModeTheme(preferTables: true),
                ],
              ),
              child: const AssetDistributionSection(accountBalances: {'Bank': 100}),
            );
          },
        ),
      );

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byType(AssetDistributionPieChart), findsNothing);
      expect(find.text('Bank'), findsOneWidget); // Verify table content
    });
  });
}
