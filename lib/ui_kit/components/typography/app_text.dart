import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

enum AppTextStyle {
  display,
  title,
  headline,
  body,
  bodyStrong,
  caption,
  overline,
}

class AppText extends StatelessWidget {
  final String text;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
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
    final kit = context.kit;

    TextStyle textStyle;
    switch (style) {
      case AppTextStyle.display:
        textStyle = kit.typography.display;
        break;
      case AppTextStyle.title:
        textStyle = kit.typography.title;
        break;
      case AppTextStyle.headline:
        textStyle = kit.typography.headline;
        break;
      case AppTextStyle.body:
        textStyle = kit.typography.body;
        break;
      case AppTextStyle.bodyStrong:
        textStyle = kit.typography.bodyStrong;
        break;
      case AppTextStyle.caption:
        textStyle = kit.typography.caption;
        break;
      case AppTextStyle.overline:
        textStyle = kit.typography.overline;
        break;
    }

    return Text(
      text,
      style: textStyle.copyWith(color: color),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
