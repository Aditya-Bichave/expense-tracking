import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
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

  group('AppTextField', () {
    testWidgets('renders basic text field', (tester) async {
      await tester.pumpWidget(buildTestWidget(const AppTextField()));

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('displays label and hint', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            label: 'Email',
            hint: 'Enter your email',
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('displays error text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            errorText: 'Invalid email format',
          ),
        ),
      );

      expect(find.text('Invalid email format'), findsOneWidget);
    });

    testWidgets('calls onChanged and onTap', (tester) async {
      String? changedValue;
      bool tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          AppTextField(
            onChanged: (val) => changedValue = val,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test input');
      expect(changedValue, 'test input');

      await tester.tap(find.byType(AppTextField));
      expect(tapped, true);
    });

    testWidgets('respects obscureText, readOnly, and enabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppTextField(
            obscureText: true,
            readOnly: true,
            enabled: false,
            prefixText: '\$',
          ),
        ),
      );

      final textField = tester.widget<AppTextField>(find.byType(AppTextField));
      expect(textField.obscureText, true);
      expect(textField.readOnly, true);
      expect(textField.enabled, false);
      expect(find.text('\$'), findsOneWidget);
    });
  });
}
