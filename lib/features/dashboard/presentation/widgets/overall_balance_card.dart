import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';

class OverallBalanceCard extends StatelessWidget {
  final FinancialOverview overview;

  const OverallBalanceCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);

    // Determine color based on balance
    final balanceColor = overview.overallBalance >= 0
        ? theme.colorScheme.primary // Use primary color for positive balance
        : theme.colorScheme.error; // Use error color for negative balance

    return AppCard(
      color: theme
          .colorScheme.surfaceContainerHighest, // Use a distinct surface color
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 20.0), // Increase vertical padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Balance',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(overview.overallBalance, currencySymbol),
              style: theme.textTheme.headlineMedium?.copyWith(
                // Make balance stand out
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis, // Prevent overflow on small screens
            ),
            // Optionally add Net Flow below
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Net Flow (Period): ',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  CurrencyFormatter.format(overview.netFlow, currencySymbol),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: overview.netFlow >= 0
                        ? Colors.green.shade700
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
