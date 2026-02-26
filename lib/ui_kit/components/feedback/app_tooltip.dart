import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const AppTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Tooltip(
      message: message,
      textStyle: kit.typography.caption.copyWith(color: kit.colors.onInverseSurface),
      decoration: BoxDecoration(
        color: kit.colors.inverseSurface,
        borderRadius: kit.radii.small,
      ),
      child: child,
    );
  }
}
