import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

class IncomeExpenseSummaryCard extends StatelessWidget {
  final FinancialOverview overview;

  const IncomeExpenseSummaryCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical margin
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 20.0), // Increase vertical padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryColumn(
              context: context,
              title: 'Income', // Simpler title
              amount: overview.totalIncome,
              color: Colors.green.shade700, // Consistent green
              icon: Icons.arrow_circle_up_outlined, // Different icon
              currencySymbol: currencySymbol,
              theme: theme,
            ),
            // Vertical divider for separation
            Container(
              height: 50, // Adjust height as needed
              width: 1,
              color: theme.dividerColor,
            ),
            _buildSummaryColumn(
              context: context,
              title: 'Expenses', // Simpler title
              amount: overview.totalExpenses,
              color: theme.colorScheme.error, // Use theme error color
              icon: Icons.arrow_circle_down_outlined, // Different icon
              currencySymbol: currencySymbol,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn({
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required String? currencySymbol,
    required ThemeData theme,
  }) {
    return Expanded(
      // Allow columns to expand equally
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Center align content
        children: [
          Row(
            // Keep icon and title together
            mainAxisSize:
                MainAxisSize.min, // Prevent row from taking full width
            children: [
              Icon(icon, color: color, size: 20), // Slightly larger icon
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(amount, currencySymbol),
            style: theme.textTheme.headlineSmall?.copyWith(
              // Use headlineSmall for amount
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Prevent overflow
          ),
        ],
      ),
    );
  }
}
