import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_badge.dart';
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

  group('AppBadge', () {
    testWidgets('renders with primary type by default', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppBadge(label: 'New'),
        ),
      );

      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('renders all badge types without error', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const Column(
            children: [
              AppBadge(label: 'Primary', type: AppBadgeType.primary),
              AppBadge(label: 'Secondary', type: AppBadgeType.secondary),
              AppBadge(label: 'Success', type: AppBadgeType.success),
              AppBadge(label: 'Warn', type: AppBadgeType.warn),
              AppBadge(label: 'Error', type: AppBadgeType.error),
            ],
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Warn'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });
  });
}
