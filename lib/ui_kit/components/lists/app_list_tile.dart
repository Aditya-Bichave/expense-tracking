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
  final bool selected;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.contentPadding,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return ListTile(
      title: DefaultTextStyle(
        style: kit.typography.body.copyWith(fontWeight: FontWeight.w500),
        child: title,
      ),
      subtitle: subtitle != null
          ? DefaultTextStyle(
              style: kit.typography.caption.copyWith(
                color: kit.colors.textSecondary,
              ),
              child: subtitle!,
            )
          : null,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      dense: dense,
      contentPadding: contentPadding ?? kit.spacing.hMd,
      selected: selected,
      selectedTileColor: kit.colors.primaryContainer.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: kit.radii.small),
    );
  }
}
