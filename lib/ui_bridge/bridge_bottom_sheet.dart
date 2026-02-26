import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_bottom_sheet.dart';

/// Bridge adapter for bottom sheets.
class BridgeBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    bool isDismissible = true,
  }) {
    // AppBottomSheet.show does not currently support isDismissible in its signature based on error logs.
    // We will ignore it for now or implement it in AppBottomSheet if needed later.
    return AppBottomSheet.show<T>(context: context, title: title, child: child);
  }
}
