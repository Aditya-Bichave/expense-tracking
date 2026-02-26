import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';

class AppStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppCard(
      onTap: onTap,
      padding: kit.spacing.allMd,
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: kit.spacing.allSm,
              decoration: BoxDecoration(
                color: (iconColor ?? kit.colors.primary).withOpacity(0.1),
                borderRadius: kit.radii.medium,
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: iconColor ?? kit.colors.primary,
                  size: 24,
                ),
                child: icon!,
              ),
            ),
            kit.spacing.gapMd,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: kit.typography.labelMedium.copyWith(
                    color: kit.colors.textSecondary,
                  ),
                ),
                kit.spacing.gapXs,
                Text(
                  value,
                  style: kit.typography.headline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
