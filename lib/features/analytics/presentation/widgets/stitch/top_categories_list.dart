import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';

class TopCategoriesList extends StatelessWidget {
  const TopCategoriesList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const BridgeEdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Categories',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              BridgeTextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: BridgeTextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCategoryItem(
            context,
            Icons.restaurant,
            Colors.orange,
            'Food & Drinks',
            '\$840.20',
            0.75,
          ),
          const SizedBox(height: 16),
          _buildCategoryItem(
            context,
            Icons.directions_car,
            Colors.blue,
            'Transport',
            '\$320.50',
            0.40,
          ),
          const SizedBox(height: 16),
          _buildCategoryItem(
            context,
            Icons.shopping_bag,
            Colors.purple,
            'Shopping',
            '\$210.00',
            0.25,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    IconData icon,
    Color color,
    String name,
    String amount,
    double progress,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BridgeDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BridgeBorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    amount,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BridgeBorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
