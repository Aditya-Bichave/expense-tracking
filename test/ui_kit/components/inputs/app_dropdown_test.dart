import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_dropdown.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Material(
        child: Builder(
          builder: (context) {
            return Theme(
              data: Theme.of(context).copyWith(
                extensions: [
                  AppKitTheme(
                    colors: AppColors(Theme.of(context).colorScheme),
                    typography: AppTypography(Theme.of(context).textTheme),
                    spacing: const AppSpacing(),
                    radii: const AppRadii(),
                    motion: const AppMotion(),
                    shadows: const AppShadows(isDark: false),
                  ),
                ],
              ),
              child: Scaffold(
                body: child,
              ),
            );
          },
        ),
      ),
    );
  }

  group('AppDropdown', () {
    testWidgets('renders properly with label and hint', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppDropdown<String>(
            label: 'Category',
            hint: 'Select Category',
            items: const [
              DropdownMenuItem(value: 'Food', child: Text('Food')),
              DropdownMenuItem(value: 'Transport', child: Text('Transport')),
            ],
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Select Category'), findsOneWidget);
    });

    testWidgets('displays selected value', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppDropdown<String>(
            value: 'Food',
            items: const [
              DropdownMenuItem(value: 'Food', child: Text('Food')),
              DropdownMenuItem(value: 'Transport', child: Text('Transport')),
            ],
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('calls onChanged when selection changes', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        buildTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppDropdown<String>(
                value: selectedValue,
                items: const [
                  DropdownMenuItem(value: 'Food', child: Text('Food')),
                  DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                ],
                onChanged: (val) {
                  setState(() => selectedValue = val);
                },
              );
            },
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Tap item
      // In dropdowns, the items show twice (one in the button, one in the menu)
      // So we target the last one which is usually in the overlay menu
      await tester.tap(find.text('Transport').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'Transport');
    });
  });
}
