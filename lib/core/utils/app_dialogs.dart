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
                foregroundColor: confirmColor ?? theme.colorScheme.primary,
              ),
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
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => _StrongConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        confirmationPhrase: confirmationPhrase,
        confirmColor: confirmColor,
      ),
    );
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _StrongConfirmationDialog extends StatefulWidget {
  const _StrongConfirmationDialog({
    required this.title,
    required this.content,
    required this.confirmText,
    required this.confirmationPhrase,
    this.confirmColor,
  });

  final String title;
  final String content;
  final String confirmText;
  final String confirmationPhrase;
  final Color? confirmColor;

  @override
  State<_StrongConfirmationDialog> createState() =>
      _StrongConfirmationDialogState();
}

class _StrongConfirmationDialogState extends State<_StrongConfirmationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.content, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 15),
            Text(
              'Please type "${widget.confirmationPhrase}" to confirm:',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.confirmationPhrase,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => value != widget.confirmationPhrase
                  ? 'Incorrect phrase'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: widget.confirmColor ?? theme.colorScheme.error,
          ),
          onPressed: _controller.text == widget.confirmationPhrase
              ? () {
                  if (_formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(true);
                  }
                }
              : null,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
