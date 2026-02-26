import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? contentWidget;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const AppDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    this.confirmLabel,
    this.onConfirm,
    this.cancelLabel,
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? content,
    Widget? contentWidget,
    String? confirmLabel,
    VoidCallback? onConfirm,
    String? cancelLabel,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        contentWidget: contentWidget,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        cancelLabel: cancelLabel,
        onCancel: onCancel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AlertDialog(
      backgroundColor: kit.colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: kit.radii.large),
      title: Text(title, style: kit.typography.headline),
      content: contentWidget ??
          (content != null
              ? Text(content!, style: kit.typography.body)
              : null),
      actions: [
        if (cancelLabel != null)
          AppButton(
            label: cancelLabel!,
            onPressed: onCancel ?? () => Navigator.pop(context),
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
          ),
        if (confirmLabel != null)
          AppButton(
            label: confirmLabel!,
            onPressed: onConfirm,
            variant: isDestructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
            size: AppButtonSize.small,
          ),
      ],
    );
  }
}
