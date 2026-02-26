import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';

/// Bridge adapter for buttons.
/// Provides specific constructors for common button variants to ease migration.
class BridgeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final UiVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool disabled;

  const BridgeButton({
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

  const BridgeButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = UiVariant.primary;

  const BridgeButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = UiVariant.secondary;

  const BridgeButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = UiVariant.ghost;

  const BridgeButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.disabled = false,
  }) : variant = UiVariant.destructive;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: variant,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      disabled: disabled,
    );
  }
}
