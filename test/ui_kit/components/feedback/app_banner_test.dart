import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_banner.dart';
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

  group('AppBanner', () {
    testWidgets('renders message and info type by default', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppBanner(message: 'Info message'),
        ),
      );

      expect(find.text('Info message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders success type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppBanner(message: 'Success!', type: AppBannerType.success),
        ),
      );

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders warning type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppBanner(message: 'Warning!', type: AppBannerType.warning),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders error type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppBanner(message: 'Error!', type: AppBannerType.error),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('triggers onDismiss callback', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        buildTestWidget(
          AppBanner(
            message: 'Dismiss me',
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, true);
    });
  });
}
