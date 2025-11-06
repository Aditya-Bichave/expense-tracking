import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class NetWorthComposition extends StatelessWidget {
  final FinancialOverview overview;

  const NetWorthComposition({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    final totalAssets = overview.totalAssets;
    final totalLiabilities = overview.totalLiabilities;
    final netWorth = overview.netWorth;
    final total = totalAssets + totalLiabilities;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Net Worth Composition', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 20,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: total,
                          width: 20,
                          borderRadius: BorderRadius.zero,
                          rodStackItems: [
                            BarChartRodStackItem(
                                0, totalAssets, Colors.green),
                            BarChartRodStackItem(totalAssets,
                                totalAssets + totalLiabilities, Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Assets'),
                Text(
                  CurrencyFormatter.format(totalAssets, currencySymbol),
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Liabilities'),
                Text(
                  CurrencyFormatter.format(totalLiabilities, currencySymbol),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Worth'),
                Text(
                  CurrencyFormatter.format(netWorth, currencySymbol),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
