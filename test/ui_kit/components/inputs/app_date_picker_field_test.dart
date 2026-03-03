import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_date_picker_field.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
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
      home: Material( // Added Material
        child: Builder(
          builder: (context) {
            // Need to apply AppKitTheme properly so it doesn't cause null errors on build
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

  group('AppDatePickerField', () {
    testWidgets('renders properly with a date', (tester) async {
      final date = DateTime(2023, 10, 5);

      await tester.pumpWidget(
        buildTestWidget(
          AppDatePickerField(
            selectedDate: date,
            onDateSelected: (_) {},
            label: 'Start Date',
          ),
        ),
      );

      expect(find.text('Start Date'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.textContaining('Oct 5, 2023'), findsOneWidget);
    });

    testWidgets('renders properly without a date', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppDatePickerField(
            selectedDate: null,
            onDateSelected: (_) {},
            hint: 'Pick a date',
          ),
        ),
      );

      expect(find.text('Pick a date'), findsOneWidget);
    });

    testWidgets('opens date picker on tap', (tester) async {
      DateTime? pickedDate;

      await tester.pumpWidget(
        buildTestWidget(
          AppDatePickerField(
            selectedDate: null,
            onDateSelected: (date) {
              pickedDate = date;
            },
          ),
        ),
      );

      // Use test specific context to trigger selection
      final BuildContext context = tester.element(find.byType(AppDatePickerField));

      // Tap on the widget that has the onTap property
      // To reliably tap, we find the AppTextField inside it
      final appTextField = tester.widget<AppTextField>(find.byType(AppTextField));
      appTextField.onTap?.call();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(pickedDate, isNotNull);
    });
  });
}
