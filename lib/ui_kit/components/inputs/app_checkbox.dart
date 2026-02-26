import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const AppCheckbox({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: kit.colors.primary,
      checkColor: kit.colors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: kit.radii.small),
      side: BorderSide(color: kit.colors.borderSubtle, width: 2),
    );
  }
}
