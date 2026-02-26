import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return ListTile(
      title: DefaultTextStyle(
        style: kit.typography.bodyLarge.copyWith(fontWeight: FontWeight.w500),
        child: title,
      ),
      subtitle: subtitle != null
          ? DefaultTextStyle(
              style: kit.typography.bodyMedium.copyWith(
                color: kit.colors.onSurfaceVariant,
              ),
              child: subtitle!,
            )
          : null,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      dense: dense,
      contentPadding: contentPadding ?? kit.spacing.hMd,
      shape: RoundedRectangleBorder(borderRadius: kit.radii.small),
      // ListTileThemeData usually handles colors, but we can enforce if needed
    );
  }
}
