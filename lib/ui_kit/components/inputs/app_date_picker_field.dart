import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'app_text_field.dart';

class AppDatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String label;
  final String? hint;

  const AppDatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.label = 'Date',
    this.hint,
  });

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = selectedDate != null
        ? DateFormat.yMMMd().format(selectedDate!)
        : '';

    return AppTextField(
      label: label,
      hint: hint,
      controller: TextEditingController(text: text),
      readOnly: true,
      onTap: () => _selectDate(context),
      suffixIcon: const Icon(Icons.calendar_today),
    );
  }
}
