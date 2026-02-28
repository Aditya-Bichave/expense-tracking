import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';

// Backward compatibility alias until migration is complete
typedef AppButtonVariant = UiVariant;
// typedef AppButtonSize = UiSize; // Can't alias closely if names differ slightly, mapping manually or keeping local for now if needed.
// But we should try to use UiSize.

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final UiVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool disabled;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = UiVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    // Sizes
    final EdgeInsets padding;
    final TextStyle textStyle;
    final double iconSize;

    switch (size) {
      case AppButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: context.space.md,
          vertical: context.space.sm,
        );
        textStyle = kit.typography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        );
        iconSize = 16;
        break;
      case AppButtonSize.medium:
        padding = const EdgeInsets.symmetric(
          horizontal: context.space.lg,
          vertical: context.space.md,
        );
        textStyle = kit.typography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        );
        iconSize = 20;
        break;
      case AppButtonSize.large:
        padding = const EdgeInsets.symmetric(
          horizontal: context.space.xxl,
          vertical: context.space.lg,
        );
        textStyle = kit.typography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        );
        iconSize = 24;
        break;
    }

    // Styles
    final Color backgroundColor;
    final Color foregroundColor;
    final Color? borderColor;

    switch (variant) {
      case UiVariant.primary:
        backgroundColor = disabled
            ? kit.colors.surfaceContainer
            : kit.colors.primary;
        foregroundColor = disabled
            ? kit.colors.textMuted
            : kit.colors.onPrimary;
        borderColor = null;
        break;
      case UiVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = disabled ? kit.colors.textMuted : kit.colors.primary;
        borderColor = disabled ? kit.colors.borderSubtle : kit.colors.border;
        break;
      case UiVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = disabled ? kit.colors.textMuted : kit.colors.primary;
        borderColor = null;
        break;
      case UiVariant.destructive:
        backgroundColor = disabled
            ? kit.colors.surfaceContainer
            : kit.colors.error;
        foregroundColor = disabled ? kit.colors.textMuted : kit.colors.onError;
        borderColor = null;
        break;
      case UiVariant.destructiveSecondary:
        backgroundColor = Colors.transparent;
        foregroundColor = disabled ? kit.colors.textMuted : kit.colors.error;
        borderColor = disabled ? kit.colors.borderSubtle : kit.colors.error;
        break;
      default:
        // Fallback for other variants not supported by button yet
        backgroundColor = kit.colors.surfaceContainer;
        foregroundColor = kit.colors.textMuted;
        borderColor = null;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          kit.spacing.gapSm,
        ] else if (icon != null) ...[
          IconTheme(
            data: IconThemeData(size: iconSize, color: foregroundColor),
            child: icon!,
          ),
          kit.spacing.gapSm,
        ],
        Text(label, style: textStyle.copyWith(color: foregroundColor)),
      ],
    );

    final buttonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(backgroundColor),
      foregroundColor: MaterialStateProperty.all(foregroundColor),
      elevation: MaterialStateProperty.all(0),
      padding: MaterialStateProperty.all(padding),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: kit.radii.button,
          side: borderColor != null
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
      ),
      overlayColor: MaterialStateProperty.all(foregroundColor.withOpacity(0.1)),
    );

    Widget button = ElevatedButton(
      onPressed: (disabled || isLoading) ? null : onPressed,
      style: buttonStyle,
      child: content,
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
