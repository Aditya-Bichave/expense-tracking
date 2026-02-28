import 'package:expense_tracker/features/settings/presentation/widgets/help_settings_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import '../../../../helpers/pump_app.dart';

class MockSharePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements SharePlatform {}

void main() {
  setUp(() {
    SharePlatform.instance = MockSharePlatform();
  });

  testWidgets('HelpSettingsSection renders tiles', (WidgetTester tester) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: HelpSettingsSection(
        isLoading: false,
        launchUrlCallback: (context, url) {},
      ),
    );

    expect(find.text('Help & Feedback'), findsOneWidget);
    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('Tell a Friend'), findsOneWidget);
    expect(find.byType(AppListTile), findsNWidgets(2));
  });

  testWidgets('HelpSettingsSection triggers Share.share on tap', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: HelpSettingsSection(
        isLoading: false,
        launchUrlCallback: (context, url) {},
      ),
    );

    when(
      () => SharePlatform.instance.share(
        any(),
        subject: any(named: 'subject'),
        sharePositionOrigin: any(named: 'sharePositionOrigin'),
      ),
    ).thenAnswer(
      (_) async => const ShareResult('success', ShareResultStatus.success),
    );

    await tester.tap(find.text('Tell a Friend'));
    await tester.pump();

    verify(
      () => SharePlatform.instance.share(
        any(),
        subject: any(named: 'subject'),
        sharePositionOrigin: any(named: 'sharePositionOrigin'),
      ),
    ).called(1);
  });
}
