import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
// import 'package:intl/intl.dart'; // No longer needed here
import 'package:expense_tracker/core/utils/currency_formatter.dart'; // Import formatter
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc

class OverallBalanceCard extends StatelessWidget {
  final FinancialOverview overview;

  const OverallBalanceCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    // Get currency symbol from SettingsBloc
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    final balanceColor = overview.overallBalance >= 0
        ? Colors.blueGrey[700] // Consider Theme colors
        : Theme.of(context).colorScheme.error;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Balance',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.blueGrey), // Consider Theme colors
            ),
            const SizedBox(height: 8),
            Text(
              // Use CurrencyFormatter
              CurrencyFormatter.format(overview.overallBalance, currencySymbol),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
