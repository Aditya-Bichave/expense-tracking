import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return IconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      color: color ?? kit.colors.textPrimary,
      splashRadius: 24,
    );
  }
}
