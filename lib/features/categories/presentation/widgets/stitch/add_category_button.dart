import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';

class AddCategoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddCategoryButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BridgeBorderRadius.circular(16),
        child: Container(
          padding: const BridgeEdgeInsets.all(16),
          decoration: BridgeDecoration(
            borderRadius: BridgeBorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                'Create Custom Category',
                style: BridgeTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
