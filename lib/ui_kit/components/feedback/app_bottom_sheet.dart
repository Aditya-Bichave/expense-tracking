import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Container(
      decoration: BoxDecoration(
        color: kit.colors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kit.radii.xl),
        ),
        boxShadow: kit.shadows.lg,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: kit.spacing.vSm,
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: kit.colors.borderSubtle,
                borderRadius: kit.radii.circular,
              ),
            ),
          ),
          if (title != null) ...[
            Padding(
              padding: kit.spacing.hMd.copyWith(bottom: kit.spacing.sm),
              child: Text(
                title!,
                style: kit.typography.title,
                textAlign: TextAlign.center,
              ),
            ),
            Divider(height: 1, color: kit.colors.borderSubtle),
          ],
          Flexible(child: child),
        ],
      ),
    );
  }
}
