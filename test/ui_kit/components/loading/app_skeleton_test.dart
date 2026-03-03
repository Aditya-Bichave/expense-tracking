import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_skeleton.dart';
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

  group('AppSkeleton', () {
    testWidgets('renders rectangle skeleton', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppSkeleton(
            width: 100,
            height: 50,
          ),
        ),
      );

      // We pump once instead of pumpAndSettle to avoid infinite animation timeout
      await tester.pump();

      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.descendant(of: find.byType(AppSkeleton), matching: find.byType(Opacity)), findsOneWidget);
      expect(find.descendant(of: find.byType(AppSkeleton), matching: find.byType(Container)), findsOneWidget);
    });

    testWidgets('renders circle skeleton', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppSkeleton(
            width: 50,
            height: 50,
            shape: BoxShape.circle,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(AppSkeleton), findsOneWidget);
    });
  });
}
