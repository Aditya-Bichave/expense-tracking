import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppFAB extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool extended;

  const AppFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    if (extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        label: Text(label!, style: kit.typography.labelLarge),
        icon: icon,
        backgroundColor: kit.colors.primaryContainer,
        foregroundColor: kit.colors.onPrimaryContainer,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: kit.colors.primaryContainer,
      foregroundColor: kit.colors.onPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: context.kit.radii.large),
      child: icon,
    );
  }
}
