import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_empty_state.dart';
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

  group('AppEmptyState', () {
    testWidgets('renders basic text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppEmptyState(
            title: 'No Data',
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
    });

    testWidgets('renders with all optional parameters', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppEmptyState(
            title: 'No Data',
            subtitle: 'Try adding some.',
            icon: Icons.hourglass_empty,
            action: ElevatedButton(
              onPressed: () {},
              child: const Text('Add Data'),
            ),
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Try adding some.'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Add Data'), findsOneWidget);
    });

    testWidgets('renders with custom illustration', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppEmptyState(
            title: 'Custom Illu',
            customIllustration: FlutterLogo(),
          ),
        ),
      );

      expect(find.byType(FlutterLogo), findsOneWidget);
      expect(find.text('Custom Illu'), findsOneWidget);
    });
  });
}
