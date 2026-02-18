import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:go_router/go_router.dart';

class StitchQuickActions extends StatelessWidget {
  const StitchQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  context,
                  Icons.add_circle,
                  'Expense',
                  true,
                  () => context.pushNamed(RouteNames.addTransaction),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionBtn(
                  context,
                  Icons.payments,
                  'Income',
                  false,
                  () => context.pushNamed(RouteNames.addTransaction),
                ),
              ), // Could pass initial type
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionBtn(
                  context,
                  Icons.group_add,
                  'Group',
                  false,
                  () {},
                ),
              ), // No route for Add Group yet?
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    IconData icon,
    String label,
    bool isPrimary,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: isPrimary
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(
                icon,
                color: isPrimary
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isPrimary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
