import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';
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

  group('AppToast', () {
    testWidgets('shows info toast', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppToast.show(context, 'Information Toast');
                },
                child: const Text('Show Info Toast'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Info Toast'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 100)); // allow snackbar to appear

      expect(find.text('Information Toast'), findsOneWidget);
    });

    testWidgets('shows success toast', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppToast.show(
                    context,
                    'Success Toast',
                    type: AppToastType.success,
                  );
                },
                child: const Text('Show Success Toast'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Success Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Success Toast'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows error toast', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppToast.show(
                    context,
                    'Error Toast',
                    type: AppToastType.error,
                  );
                },
                child: const Text('Show Error Toast'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Error Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error Toast'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}
