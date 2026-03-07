import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

enum AppBadgeType { primary, secondary, success, warn, error }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeType type;

  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    Color backgroundColor;
    Color textColor;

    switch (type) {
      case AppBadgeType.primary:
        backgroundColor = kit.colors.primaryContainer;
        textColor = kit.colors.onPrimaryContainer;
        break;
      case AppBadgeType.secondary:
        backgroundColor = kit.colors.secondaryContainer;
        textColor = kit.colors.onSecondaryContainer;
        break;
      case AppBadgeType.success:
        backgroundColor = kit.colors.success.withOpacity(0.1);
        textColor = kit.colors.success;
        break;
      case AppBadgeType.warn:
        backgroundColor = kit.colors.warn.withOpacity(0.1);
        textColor = kit.colors.warn;
        break;
      case AppBadgeType.error:
        backgroundColor = kit.colors.errorContainer;
        textColor = kit.colors.onErrorContainer;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.sm,
        vertical: context.space.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: kit.radii.small,
      ),
      child: Text(
        label,
        style: kit.typography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
