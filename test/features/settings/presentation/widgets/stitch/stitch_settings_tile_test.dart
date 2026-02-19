import 'package:expense_tracker/features/settings/presentation/widgets/stitch/stitch_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StitchSettingsTile renders correctly and handles tap', (
    WidgetTester tester,
  ) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StitchSettingsTile(
            icon: Icons.settings,
            title: 'Test Title',
            subtitle: 'Test Subtitle',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Subtitle'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    await tester.tap(find.byType(StitchSettingsTile));
    expect(tapped, isTrue);
  });
}
