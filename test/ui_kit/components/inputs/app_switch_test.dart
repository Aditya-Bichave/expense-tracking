import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_switch.dart';
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

  group('AppSwitch', () {
    testWidgets('renders correct initial state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppSwitch(
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      final cupertinoSwitch = tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch));
      expect(cupertinoSwitch.value, true);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      bool? switchValue = false;

      await tester.pumpWidget(
        buildTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitch(
                value: switchValue!,
                onChanged: (val) {
                  setState(() => switchValue = val);
                },
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pumpAndSettle();

      expect(switchValue, true);
    });
  });
}
