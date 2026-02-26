import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    // We can't access context.kit easily here without BuildContext, but we have it.
    // However, showModalBottomSheet builder has its own context.

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent, // Handle styling in builder
      builder: (ctx) {
        final kit = ctx.kit;
        return Container(
          decoration: BoxDecoration(
            color: kit.colors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(kit.radii.lg),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom, // Keyboard handling
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: kit.spacing.vSm,
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kit.colors.outlineVariant,
                    borderRadius: kit.radii.circular,
                  ),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        );
      },
    );
  }
}
