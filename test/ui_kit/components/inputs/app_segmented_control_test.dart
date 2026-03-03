import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_segmented_control.dart';
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
          }
        ),
      ),
    );
  }

  group('AppSegmentedControl', () {
    testWidgets('renders segments', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppSegmentedControl<int>(
            groupValue: 1,
            children: const {
              1: Text('Option 1'),
              2: Text('Option 2'),
            },
            onValueChanged: (val) {},
          ),
        ),
      );

      expect(find.byType(CupertinoSlidingSegmentedControl<int>), findsOneWidget);
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
    });

    testWidgets('calls onValueChanged on selection', (tester) async {
      int? selectedValue = 1;

      await tester.pumpWidget(
        buildTestWidget(
          AppSegmentedControl<int>(
            groupValue: selectedValue,
            children: const {
              1: Text('One'),
              2: Text('Two'),
            },
            onValueChanged: (val) {
              selectedValue = val;
            },
          ),
        ),
      );

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(selectedValue, 2);
    });
  });
}
