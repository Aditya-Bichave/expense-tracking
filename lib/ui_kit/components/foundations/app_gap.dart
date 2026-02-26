import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppGap extends StatelessWidget {
  final double size;

  const AppGap(this.size, {super.key});

  factory AppGap.xs(BuildContext context) => AppGap(context.kit.spacing.xs);
  factory AppGap.sm(BuildContext context) => AppGap(context.kit.spacing.sm);
  factory AppGap.md(BuildContext context) => AppGap(context.kit.spacing.md);
  factory AppGap.lg(BuildContext context) => AppGap(context.kit.spacing.lg);
  factory AppGap.xl(BuildContext context) => AppGap(context.kit.spacing.xl);

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size);
  }
}
