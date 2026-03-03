import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
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

  group('AppDialog', () {
    testWidgets('renders title and content', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppDialog(
            title: 'Test Title',
            content: 'Test Content',
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders action buttons and triggers callbacks', (tester) async {
      bool confirmTapped = false;
      bool cancelTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          AppDialog(
            title: 'Action Dialog',
            confirmLabel: 'Confirm',
            onConfirm: () => confirmTapped = true,
            cancelLabel: 'Cancel',
            onCancel: () => cancelTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Confirm'));
      expect(confirmTapped, true);

      await tester.tap(find.text('Cancel'));
      expect(cancelTapped, true);
    });

    testWidgets('shows dialog using static method', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialog.show(
                    context: context,
                    title: 'Static Show',
                    content: 'Content text',
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Static Show'), findsOneWidget);
      expect(find.text('Content text'), findsOneWidget);
    });
  });
}
