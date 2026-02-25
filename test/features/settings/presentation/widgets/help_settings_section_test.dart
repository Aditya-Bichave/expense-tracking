import 'package:expense_tracker/features/settings/presentation/widgets/help_settings_section.dart';
import 'package:expense_tracker/core/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('HelpSettingsSection triggers Share.share on tap', (
    WidgetTester tester,
  ) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final log = <MethodCall>[];

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      methodCall,
    ) async {
      log.add(methodCall);
      return null;
    });

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

    expect(log, hasLength(1));
    expect(log.first.method, 'share');
    // Optionally check arguments
    // expect(log.first.arguments['text'], contains('Spend Savvy'));

    // Clean up
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });
}
