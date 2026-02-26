import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onSelected;
  final Widget? icon;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kit.colors.primaryContainer : kit.colors.surfaceContainer,
          borderRadius: kit.radii.chip,
          border: Border.all(
            color: isSelected ? kit.colors.primary : kit.colors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              kit.spacing.gapXs,
            ],
            Text(
              label,
              style: kit.typography.labelMedium.copyWith(
                color: isSelected ? kit.colors.onPrimaryContainer : kit.colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
