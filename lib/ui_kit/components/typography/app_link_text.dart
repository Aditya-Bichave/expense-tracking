import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppLinkText extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final TextStyle? style;

  const AppLinkText(this.text, {super.key, this.onTap, this.style});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: (style ?? kit.typography.body).copyWith(
          color: kit.colors.primary,
          decoration: TextDecoration.underline,
          decorationColor: kit.colors.primary,
        ),
      ),
    );
  }
}
