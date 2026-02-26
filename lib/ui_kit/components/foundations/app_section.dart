import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Padding(
      padding: padding ?? kit.spacing.hMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: kit.typography.headline),
              if (action != null) action!,
            ],
          ),
          kit.spacing.gapSm,
          child,
        ],
      ),
    );
  }
}
