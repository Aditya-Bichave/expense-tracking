import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverallBalanceCard extends StatelessWidget {
  final FinancialOverview overview;

  const OverallBalanceCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
        symbol: '\$', decimalDigits: 2); // TODO: Make currency configurable
    // Use the correct field 'overallBalance'
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
              // Use the correct field 'overallBalance'
              currencyFormat.format(overview.overallBalance),
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
