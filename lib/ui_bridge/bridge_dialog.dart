import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';

/// Bridge adapter for dialogs.
class BridgeDialog {
  static Future<void> showConfirm({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return AppDialog.show(
      context: context,
      title: title,
      content: content,
      onConfirm: onConfirm,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    );
  }

  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String content,
    String buttonLabel = 'OK',
  }) {
    // Assuming AppDialog might not have a direct 'alert' convenience method exposed yet,
    // we can use show with null onCancel or custom implementation.
    // For now, mapping to show with no cancel action implies an alert.
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
