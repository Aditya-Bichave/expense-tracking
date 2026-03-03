import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
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

  group('AppText', () {
    testWidgets('renders text correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AppText('Hello World')),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('applies different styles', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const Column(
            children: [
              AppText('Display', style: AppTextStyle.display),
              AppText('Title', style: AppTextStyle.title),
              AppText('Headline', style: AppTextStyle.headline),
              AppText('Body', style: AppTextStyle.body),
              AppText('BodyStrong', style: AppTextStyle.bodyStrong),
              AppText('Caption', style: AppTextStyle.caption),
              AppText('Overline', style: AppTextStyle.overline),
            ],
          ),
        ),
      );

      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Caption'), findsOneWidget);
      // Ensures no errors during build for all styles
    });

    testWidgets('applies custom color, alignment and overflow', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppText(
            'Custom Text',
            color: Colors.red,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Custom Text'));
      expect(textWidget.style?.color, Colors.red);
      expect(textWidget.textAlign, TextAlign.center);
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });
  });
}
