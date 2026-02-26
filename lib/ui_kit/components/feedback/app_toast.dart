import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

enum AppToastType {
  success,
  error,
  info,
}

class AppToast {
  static void show(BuildContext context, String message, {AppToastType type = AppToastType.info}) {
    final kit = context.kit; // This might fail if context is not mounted, usually handled by caller.

    // We can't access context.kit inside ScafoldMessenger directly without a context that has the theme.
    // Assuming context passed has theme.

    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case AppToastType.success:
        backgroundColor = kit.colors.success;
        textColor = kit.colors.onPrimary; // assuming success is dark enough
        icon = Icons.check_circle;
        break;
      case AppToastType.error:
        backgroundColor = kit.colors.error;
        textColor = kit.colors.onError;
        icon = Icons.error;
        break;
      case AppToastType.info:
        backgroundColor = kit.colors.inverseSurface;
        textColor = kit.colors.onInverseSurface;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            kit.spacing.gapSm,
            Expanded(
              child: Text(
                message,
                style: kit.typography.body.copyWith(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: kit.radii.small),
        margin: kit.spacing.allMd,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
