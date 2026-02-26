import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const AppDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Divider(
      height: height ?? 16.0,
      thickness: thickness ?? 1.0,
      color: color ?? kit.colors.borderSubtle,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
