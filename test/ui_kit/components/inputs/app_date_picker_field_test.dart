import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_date_picker_field.dart';

void main() {
  Widget buildTestWidget({
    DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
    String label = 'Date',
    String? hint,
  }) {
    return MaterialApp(
      home: Material(
        child: AppDatePickerField(
          selectedDate: selectedDate,
          onDateSelected: onDateSelected,
          label: label,
          hint: hint,
        ),
      ),
    );
  }

  group('AppDatePickerField', () {
    testWidgets('renders hint when no date provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(onDateSelected: (_) {}, hint: 'Select Date'),
      );

      expect(find.text('Select Date'), findsOneWidget);
    });

    testWidgets('renders formatted date when provided', (tester) async {
      final testDate = DateTime(2023, 10, 15);
      final formattedDate = DateFormat.yMMMd().format(testDate);

      await tester.pumpWidget(
        buildTestWidget(selectedDate: testDate, onDateSelected: (_) {}),
      );

      expect(find.text(formattedDate), findsOneWidget);
    });

    testWidgets('shows DatePicker when tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget(onDateSelected: (_) {}));

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('calls onDateSelected when new date is picked', (tester) async {
      DateTime? pickedDate;
      await tester.pumpWidget(
        buildTestWidget(
          selectedDate: DateTime(2023, 1, 1),
          onDateSelected: (date) => pickedDate = date,
        ),
      );

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(pickedDate, isNotNull);
      expect(pickedDate!.day, 15);
    });
  });
}
