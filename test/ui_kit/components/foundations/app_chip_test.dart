import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_chip.dart';
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

  group('AppChip', () {
    testWidgets('renders label and icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppChip(
            label: 'Filter',
            icon: Icon(Icons.filter_list),
          ),
        ),
      );

      expect(find.text('Filter'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('renders selected state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppChip(
            label: 'Selected',
            isSelected: true,
          ),
        ),
      );

      expect(find.text('Selected'), findsOneWidget);
    });

    testWidgets('triggers onSelected', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          AppChip(
            label: 'Tap Me',
            onSelected: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, true);
    });
  });
}
