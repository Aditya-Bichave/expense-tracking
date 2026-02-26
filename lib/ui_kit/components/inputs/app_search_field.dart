import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hint;

  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint ?? 'Search...',
        prefixIcon: Icon(Icons.search, color: kit.colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: kit.radii.circular,
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: kit.colors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
      style: kit.typography.body,
    );
  }
}
