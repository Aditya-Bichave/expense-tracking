import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/placeholder_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BudgetsSubTab extends StatelessWidget {
  const BudgetsSubTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded,
                size: 60, color: theme.colorScheme.secondary.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Budgeting Feature Coming Soon!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Plan your spending and track your progress against budget goals.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create Budget'),
              onPressed: () => context.pushNamed(
                  RouteNames.createBudget), // Navigate to placeholder
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: theme.textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
