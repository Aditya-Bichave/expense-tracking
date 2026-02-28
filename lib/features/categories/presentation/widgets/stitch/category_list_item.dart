import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';

class CategoryListItem extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const CategoryListItem({
    super.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const BridgeEdgeInsets.symmetric(vertical: 4),
      decoration: BridgeDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BridgeBorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: BridgeListTile(
        onTap: onTap,
        contentPadding: const BridgeEdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BridgeDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BridgeBorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          name,
          style: const BridgeTextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          style: BridgeTextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.more_vert,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
