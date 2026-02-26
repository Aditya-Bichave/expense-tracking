// lib/core/widgets/app_dropdown_form_field.dart
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:flutter/material.dart';

class AppDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final String labelText;
  final String? hintText;
  // --- Ensure this parameter exists and accepts Widget? ---
  final Widget? prefixIcon;
  // --- End Ensure ---
  final bool isExpanded;
  final EdgeInsets? contentPadding; // Allow overriding padding

  const AppDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    required this.labelText,
    this.hintText,
    // --- Ensure this parameter exists ---
    this.prefixIcon,
    // --- End Ensure ---
    this.isExpanded = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;
    final modeTheme = context.modeTheme;

    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: inputTheme.border ?? const OutlineInputBorder(),
        enabledBorder: inputTheme.enabledBorder,
        focusedBorder: inputTheme.focusedBorder,
        errorBorder: inputTheme.errorBorder,
        focusedErrorBorder: inputTheme.focusedErrorBorder,
        filled: inputTheme.filled,
        fillColor: inputTheme.fillColor,
        contentPadding:
            contentPadding ??
            inputTheme.contentPadding ??
            modeTheme?.listItemPadding.copyWith(top: 14, bottom: 14),
        isDense: inputTheme.isDense,
        floatingLabelBehavior: inputTheme.floatingLabelBehavior,
        // --- Use the prefixIcon parameter ---
        prefixIcon: prefixIcon,
        // --- End Use ---
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      // Consider styling dropdown menu via theme.dropdownMenuTheme
    );
  }
}
