import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

/// Bridge adapter for text display.
/// Wraps [AppText] but provides a simpler API for migration.
class BridgeText extends StatelessWidget {
  final String text;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const BridgeText(
    this.text, {
    super.key,
    this.style = AppTextStyle.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      style: style,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
