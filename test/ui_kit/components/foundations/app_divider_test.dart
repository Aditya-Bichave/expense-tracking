import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_divider.dart';
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

  group('AppDivider', () {
    testWidgets('renders default divider', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppDivider(),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders with custom properties', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppDivider(
            height: 32,
            thickness: 2,
            color: Colors.red,
            indent: 10,
            endIndent: 20,
          ),
        ),
      );

      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.height, 32);
      expect(divider.thickness, 2);
      expect(divider.color, Colors.red);
      expect(divider.indent, 10);
      expect(divider.endIndent, 20);
    });
  });
}
