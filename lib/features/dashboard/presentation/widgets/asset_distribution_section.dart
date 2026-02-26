// lib/features/dashboard/presentation/widgets/asset_distribution_section.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // For UIMode & theme
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart'; // For useTables pref
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssetDistributionSection extends StatelessWidget {
  final Map<String, double> accountBalances;

  const AssetDistributionSection({super.key, required this.accountBalances});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    Theme.of(context);
    final modeTheme = context.modeTheme;
    final isQuantum = settingsState.uiMode == UIMode.quantum;
    final useTables = modeTheme?.preferDataTableForLists ?? false;

    // Quantum + Prefer Tables = Show Table
    if (isQuantum && useTables) {
      return _buildQuantumAssetTable(context, accountBalances, settingsState);
    }
    // Elemental or (Quantum + No Tables Pref) = Show Pie Chart
    else if (!isQuantum || (isQuantum && !useTables)) {
      return AssetDistributionPieChart(accountBalances: accountBalances);
    }
    // Fallback (shouldn't be reached)
    else {
      return const SizedBox.shrink();
    }
  }

  // Extracted table building logic from original DashboardPage
  Widget _buildQuantumAssetTable(
    BuildContext context,
    Map<String, double> accountBalances,
    SettingsState settings,
  ) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;
    final rows = accountBalances.entries.map((entry) {
      return DataRow(
        cells: [
          DataCell(Text(entry.key, style: theme.textTheme.bodyMedium)),
          DataCell(
            Text(
              CurrencyFormatter.format(entry.value, currencySymbol),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: entry.value >= 0
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      );
    }).toList();

    if (rows.isEmpty) {
      return Card(
        margin:
            theme.cardTheme.margin ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "No accounts with balance.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }
    return Card(
      margin:
          theme.cardTheme.margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      clipBehavior: theme.cardTheme.clipBehavior ?? Clip.none,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Asset Balances', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Account')),
                  DataColumn(label: Text('Balance'), numeric: true),
                ],
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
