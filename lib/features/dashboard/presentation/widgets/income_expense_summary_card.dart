import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';

class IncomeExpenseSummaryCard extends StatelessWidget {
  final FinancialOverview overview;

  const IncomeExpenseSummaryCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
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
            ),
            _buildSummaryColumn(
              context,
              'Total Expenses',
              overview.totalExpenses,
              Colors.red,
              Icons.arrow_downward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(BuildContext context, String title, double amount,
      Color color, IconData icon) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
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
          currencyFormat.format(amount),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
