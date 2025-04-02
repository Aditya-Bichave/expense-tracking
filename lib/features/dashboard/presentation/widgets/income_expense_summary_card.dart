import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
// import 'package:intl/intl.dart'; // No longer needed here
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart'; // Import formatter
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc

class IncomeExpenseSummaryCard extends StatelessWidget {
  final FinancialOverview overview;

  const IncomeExpenseSummaryCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    // Get currency symbol from SettingsBloc
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryColumn(
              context,
              'Total Income',
              overview.totalIncome,
              Colors.green,
              Icons.arrow_upward,
              currencySymbol, // Pass symbol
            ),
            _buildSummaryColumn(
              context,
              'Total Expenses',
              overview.totalExpenses,
              Colors.red,
              Icons.arrow_downward,
              currencySymbol, // Pass symbol
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(BuildContext context, String title, double amount,
      Color color, IconData icon, String? currencySymbol) {
    // Added currencySymbol param
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.blueGrey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          // Use CurrencyFormatter
          CurrencyFormatter.format(amount, currencySymbol),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
