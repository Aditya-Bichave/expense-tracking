// lib/core/utils/app_dialogs.dart
import 'package:flutter/material.dart';

class AppDialogs {
  // --- CORRECTED: context is the first positional argument ---
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool barrierDismissible = false,
  }) async {
    // ----------------------------------------------------------
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(content, style: theme.textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: Text(cancelText),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: confirmColor ?? theme.colorScheme.primary),
              child: Text(confirmText),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );
  }

  // --- CORRECTED: context is the first positional argument ---
  static Future<bool?> showStrongConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    required String confirmationPhrase,
    Color? confirmColor,
    bool barrierDismissible = false,
  }) async {
    // ----------------------------------------------------------
    final theme = Theme.of(context);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool isDisposed = false;
    void disposeController() {
      if (!isDisposed) {
        controller.dispose();
        isDisposed = true;
      }
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 15),
                    Text('Please type "$confirmationPhrase" to confirm:',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                          hintText: confirmationPhrase,
                          border: const OutlineInputBorder(),
                          isDense: true),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) => (value != confirmationPhrase)
                          ? 'Incorrect phrase'
                          : null,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: confirmColor ?? theme.colorScheme.error),
                  onPressed: value.text == confirmationPhrase
                      ? () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.of(ctx).pop(true);
                          }
                        }
                      : null,
                  child: Text(confirmText),
                );
              },
            ),
          ],
        );
      },
    ).whenComplete(disposeController);
  }
}
