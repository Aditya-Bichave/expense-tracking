import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_bottom_sheet.dart';
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

  group('AppBottomSheet', () {
    testWidgets('renders inline properly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppBottomSheet(
            title: 'Sheet Title',
            child: Text('Sheet Content'),
          ),
        ),
      );

      expect(find.text('Sheet Title'), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('shows bottom sheet using static method', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppBottomSheet.show(
                    context: context,
                    title: 'Static Sheet',
                    child: const Text('Modal Content'),
                  );
                },
                child: const Text('Show Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Static Sheet'), findsOneWidget);
      expect(find.text('Modal Content'), findsOneWidget);
    });
  });
}
