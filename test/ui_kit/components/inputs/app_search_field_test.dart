import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_search_field.dart';
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
          }
        ),
      ),
    );
  }

  group('AppSearchField', () {
    testWidgets('renders correctly with default hint', (tester) async {
      await tester.pumpWidget(buildTestWidget(const AppSearchField()));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders correctly with custom hint', (tester) async {
      await tester.pumpWidget(buildTestWidget(const AppSearchField(hint: 'Find expense')));

      expect(find.text('Find expense'), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;
      await tester.pumpWidget(
        buildTestWidget(
          AppSearchField(
            onChanged: (value) => changedValue = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'coffee');
      expect(changedValue, 'coffee');
    });

    testWidgets('respects controller value', (tester) async {
      final controller = TextEditingController(text: 'groceries');
      await tester.pumpWidget(
        buildTestWidget(
          AppSearchField(controller: controller),
        ),
      );

      expect(find.text('groceries'), findsOneWidget);
    });
  });
}
