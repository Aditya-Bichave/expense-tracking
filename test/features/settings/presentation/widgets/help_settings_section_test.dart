import 'package:expense_tracker/features/settings/presentation/widgets/help_settings_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  final List<MethodCall> methodCalls = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return null;
        });
    methodCalls.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
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

  testWidgets('HelpSettingsSection triggers share channel on tap', (
    WidgetTester tester,
  ) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: HelpSettingsSection(
        isLoading: false,
        launchUrlCallback: (context, url) {},
      ),
    );

    await tester.tap(find.text('Tell a Friend'));
    await tester.pump();

    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, 'share');
  });
}
