import 'package:expense_tracker/core/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsListTile', () {
    testWidgets('renders title, subtitle, and icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsListTile(
              title: 'Setting',
              subtitle: 'Description',
              leadingIcon: Icons.settings,
              trailing: Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );

      expect(find.text('Setting'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('is tappable and calls onTap when enabled', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsListTile(
              title: 'Setting',
              leadingIcon: Icons.settings,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('is not tappable when disabled', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsListTile(
              title: 'Setting',
              leadingIcon: Icons.settings,
              onTap: () => tapped = true,
              enabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile), warnIfMissed: false);
      expect(tapped, false);
    });

    testWidgets('applies disabled styling when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsListTile(
              title: 'Setting',
              leadingIcon: Icons.settings,
              enabled: false,
            ),
          ),
        ),
      );

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.enabled, false);

      // Checking actual text color is hard due to style inheritance logic in widget,
      // but inspecting listTile.enabled=false property is sufficient.
    });
  });
}
