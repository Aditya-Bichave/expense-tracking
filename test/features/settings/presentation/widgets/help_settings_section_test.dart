import 'package:expense_tracker/features/settings/presentation/widgets/help_settings_section.dart';
import 'package:expense_tracker/core/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('HelpSettingsSection renders tiles', (WidgetTester tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: HelpSettingsSection(
        isLoading: false,
        launchUrlCallback: (context, url) {},
      ),
    );

    // SectionHeader uppercases the title
    expect(find.text('HELP & FEEDBACK'), findsOneWidget);
    expect(find.byType(SettingsListTile), findsAtLeastNWidgets(1));
  });

  testWidgets('HelpSettingsSection shows snackbar on tap', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: Scaffold(
        body: HelpSettingsSection(
          isLoading: false,
          launchUrlCallback: (context, url) {},
        ),
      ),
    );

    await tester.tap(find.text('Tell a Friend'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Share (Not Implemented)'), findsOneWidget);
  });
}
