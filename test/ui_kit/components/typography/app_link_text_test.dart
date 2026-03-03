import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_link_text.dart';
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

  group('AppLinkText', () {
    testWidgets('renders properly with underline', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppLinkText('Click Here'),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Click Here'));
      expect(textWidget.style?.decoration, TextDecoration.underline);
    });

    testWidgets('calls onTap when clicked', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          AppLinkText(
            'Click Here',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Click Here'));
      expect(tapped, true);
    });
  });
}
