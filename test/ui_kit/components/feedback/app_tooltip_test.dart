import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_tooltip.dart';
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

  group('AppTooltip', () {
    testWidgets('renders child and message', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTooltip(
            message: 'Tooltip message',
            child: Text('Hover me'),
          ),
        ),
      );

      expect(find.text('Hover me'), findsOneWidget);

      // Tooltip message is rendered using an Overlay when hovered/long-pressed
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Tooltip message');
    });

    testWidgets('shows message on long press', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTooltip(
            message: 'Tooltip info',
            child: Icon(Icons.info),
          ),
        ),
      );

      // Find the widget to long press
      await tester.longPress(find.byIcon(Icons.info));
      await tester.pumpAndSettle();

      // Ensure the message shows up
      expect(find.text('Tooltip info'), findsOneWidget);
    });
  });
}
