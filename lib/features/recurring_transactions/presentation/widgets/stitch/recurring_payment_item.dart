import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class RecurringPaymentItem extends StatelessWidget {
  final String title;
  final String schedule;
  final String date;
  final String amount;
  final String status;
  final IconData icon;
  final Color color;

  const RecurringPaymentItem({
    super.key,
    required this.title,
    required this.schedule,
    required this.date,
    required this.amount,
    required this.status,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: context.kit.radii.large,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: context.space.allLg,
          margin: context.space.vXs,
          decoration: BridgeDecoration(
            color: theme.colorScheme.surface.withOpacity(0.4),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BridgeDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: context.kit.radii.medium,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$schedule • $date',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BridgeDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: context.kit.radii.medium,
                    ),
                    child: Text(
                      status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
