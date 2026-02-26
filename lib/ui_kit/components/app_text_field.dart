import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.prefixText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: kit.radii.medium,
          borderSide: BorderSide(color: kit.colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: kit.radii.medium,
          borderSide: BorderSide(color: kit.colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: kit.radii.medium,
          borderSide: BorderSide(color: kit.colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: kit.radii.medium,
          borderSide: BorderSide(color: kit.colors.error),
        ),
        contentPadding: kit.spacing.allMd,
        filled: true,
        fillColor: kit.colors.surface,
      ),
      style: kit.typography.bodyLarge,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
    );
  }
}
