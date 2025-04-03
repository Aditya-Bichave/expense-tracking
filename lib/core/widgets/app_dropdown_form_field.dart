import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:flutter/material.dart';

class AppDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final String labelText;
  final String? hintText;
  final IconData? prefixIconData;
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
    this.prefixIconData,
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
        // Use override, then theme, then modeTheme, then fallback
        contentPadding: contentPadding ??
            inputTheme.contentPadding ??
            modeTheme?.listItemPadding?.copyWith(top: 14, bottom: 14),
        isDense: inputTheme.isDense,
        floatingLabelBehavior: inputTheme.floatingLabelBehavior,
        prefixIcon: prefixIconData != null ? Icon(prefixIconData) : null,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      // Consider styling dropdown menu via theme.dropdownMenuTheme
    );
  }
}
