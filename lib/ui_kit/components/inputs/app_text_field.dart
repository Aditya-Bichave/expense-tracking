import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
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
  final bool enabled;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
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
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: kit.typography.labelMedium.copyWith(
              color: errorText != null
                  ? kit.colors.error
                  : kit.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          kit.spacing.gapXs,
        ],
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            prefixText: prefixText,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: kit.radii.medium,
              borderSide: BorderSide(color: kit.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: kit.radii.medium,
              borderSide: BorderSide(color: kit.colors.borderSubtle),
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
            fillColor: enabled
                ? kit.colors.surfaceContainer
                : kit.colors.surface.withOpacity(0.5),
          ),
          style: kit.typography.body,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
        ),
      ],
    );
  }
}
