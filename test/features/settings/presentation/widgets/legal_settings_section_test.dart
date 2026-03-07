import 'package:expense_tracker/features/settings/presentation/widgets/legal_settings_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('LegalSettingsSection renders tiles', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: LegalSettingsSection(
        isLoading: false,
        launchUrlCallback: (context, url) {},
      ),
    );

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Open Source Licenses'), findsOneWidget);
    expect(find.byType(AppListTile), findsNWidgets(3));
  });

  testWidgets('LegalSettingsSection triggers callbacks', (
    WidgetTester tester,
  ) async {
    String? launchedUrl;
    await pumpWidgetWithProviders(
      tester: tester,
      widget: Scaffold(
        body: LegalSettingsSection(
          isLoading: false,
          launchUrlCallback: (context, url) {
            launchedUrl = url;
          },
        ),
      ),
    );

    await tester.tap(find.text('Privacy Policy'));
    expect(launchedUrl, contains('privacy'));

    await tester.tap(find.text('Terms of Service'));
    expect(launchedUrl, contains('terms'));
  });
}
