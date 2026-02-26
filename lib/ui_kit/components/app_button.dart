import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

enum AppButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
  secondaryDestructive,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget?
  icon; // Changed to Widget to support Loading indicator or custom icons
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    // Determine style based on variant
    final ButtonStyle style;
    switch (variant) {
      case AppButtonVariant.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: kit.colors.primary,
          foregroundColor: kit.colors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: kit.radii.medium),
          padding: kit.spacing.hLg + kit.spacing.vMd,
        );
        break;
      case AppButtonVariant.secondary:
        style = OutlinedButton.styleFrom(
          foregroundColor: kit.colors.primary,
          side: BorderSide(color: kit.colors.outline),
          shape: RoundedRectangleBorder(borderRadius: kit.radii.medium),
          padding: kit.spacing.hLg + kit.spacing.vMd,
        );
        break;
      case AppButtonVariant.ghost:
        style = TextButton.styleFrom(
          foregroundColor: kit.colors.primary,
          shape: RoundedRectangleBorder(borderRadius: kit.radii.medium),
          padding: kit.spacing.hMd + kit.spacing.vSm,
        );
        break;
      case AppButtonVariant.destructive:
        style = ElevatedButton.styleFrom(
          backgroundColor: kit.colors.error,
          foregroundColor: kit.colors.onError,
          shape: RoundedRectangleBorder(borderRadius: kit.radii.medium),
          padding: kit.spacing.hLg + kit.spacing.vMd,
        );
        break;
      case AppButtonVariant.secondaryDestructive:
        style = OutlinedButton.styleFrom(
          foregroundColor: kit.colors.error,
          side: BorderSide(color: kit.colors.error),
          shape: RoundedRectangleBorder(borderRadius: kit.radii.medium),
          padding: kit.spacing.hLg + kit.spacing.vMd,
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.secondary ||
                        variant == AppButtonVariant.ghost ||
                        variant == AppButtonVariant.secondaryDestructive
                    ? (variant == AppButtonVariant.secondaryDestructive
                          ? kit.colors.error
                          : kit.colors.primary)
                    : kit.colors.onPrimary,
              ),
            ),
          ),
          SizedBox(width: kit.spacing.sm),
        ] else if (icon != null) ...[
          icon!,
          SizedBox(width: kit.spacing.sm),
        ],
        Text(
          label,
          style: kit.typography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final Widget button;
    if (variant == AppButtonVariant.secondary ||
        variant == AppButtonVariant.secondaryDestructive) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: content,
      );
    } else if (variant == AppButtonVariant.ghost) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: content,
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: content,
      );
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
