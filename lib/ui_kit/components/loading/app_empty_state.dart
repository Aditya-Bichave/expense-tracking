import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;
  final Widget? customIllustration;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Center(
      child: Padding(
        padding: kit.spacing.allXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (customIllustration != null)
              customIllustration!
            else if (icon != null)
              Icon(icon, size: 64, color: kit.colors.textMuted),
            kit.spacing.gapLg,
            Text(
              title,
              style: kit.typography.headline,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              kit.spacing.gapSm,
              Text(
                subtitle!,
                style: kit.typography.body.copyWith(
                  color: kit.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[kit.spacing.gapXl, action!],
          ],
        ),
      ),
    );
  }
}
