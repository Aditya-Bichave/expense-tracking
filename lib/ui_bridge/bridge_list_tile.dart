import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';

/// Bridge adapter for list tiles.
/// Wraps [AppListTile].
class BridgeListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final bool selected;

  const BridgeListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      dense: dense,
      selected: selected,
    );
  }
}
