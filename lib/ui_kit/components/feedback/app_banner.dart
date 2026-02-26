import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

enum AppBannerType {
  info,
  success,
  warning,
  error,
}

class AppBanner extends StatelessWidget {
  final String message;
  final AppBannerType type;
  final VoidCallback? onDismiss;
  final Widget? action;

  const AppBanner({
    super.key,
    required this.message,
    this.type = AppBannerType.info,
    this.onDismiss,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;

    switch (type) {
      case AppBannerType.info:
        backgroundColor = kit.colors.primaryContainer;
        foregroundColor = kit.colors.onPrimaryContainer;
        icon = Icons.info_outline;
        break;
      case AppBannerType.success:
        backgroundColor = kit.colors.success.withOpacity(0.1);
        foregroundColor = kit.colors.success; // Assuming text color works
        icon = Icons.check_circle_outline;
        break;
      case AppBannerType.warning:
        backgroundColor = kit.colors.warn.withOpacity(0.1);
        foregroundColor = kit.colors.warn;
        icon = Icons.warning_amber_rounded;
        break;
      case AppBannerType.error:
        backgroundColor = kit.colors.errorContainer;
        foregroundColor = kit.colors.onErrorContainer;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: kit.spacing.allMd,
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor, size: 20),
          kit.spacing.gapMd,
          Expanded(
            child: Text(
              message,
              style: kit.typography.bodySmall.copyWith(color: foregroundColor),
            ),
          ),
          if (action != null) action!,
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: foregroundColor, size: 20),
            ),
        ],
      ),
    );
  }
}
