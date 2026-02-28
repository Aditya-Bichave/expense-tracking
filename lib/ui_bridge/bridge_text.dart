// lib/ui_bridge/bridge_text.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';

/// Bridge adapter for text display.
/// Wraps [AppText] but provides a simpler API for migration.
class BridgeText extends StatelessWidget {
  final String text;
  final TextStyle? style; // Allowing TextStyle for migration compatibility
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const BridgeText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // If a TextStyle is provided, use standard Text widget to support custom styles during migration.
    // Ideally we should map TextStyle to AppTextStyle, but that's hard if styles are custom.
    if (style != null) {
      return Text(
        text,
        style: style?.copyWith(color: color), // Apply color override if present
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Default fallback to AppText body if no style provided (should not happen if we are careful)
    return AppText(
      text,
      style: AppTextStyle.body,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
