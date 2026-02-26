// lib/features/dashboard/presentation/widgets/asset_distribution_section.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // For UIMode & theme
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart'; // For useTables pref
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_text.dart';

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
    final kit = context.kit;
    final currencySymbol = settings.currencySymbol;
    final rows = accountBalances.entries.map((entry) {
      return DataRow(
        cells: [
          DataCell(BridgeText(entry.key, style: kit.typography.body)),
          DataCell(
            BridgeText(
              CurrencyFormatter.format(entry.value, currencySymbol),
              style: kit.typography.body.copyWith(
                color: entry.value >= 0
                    ? kit.colors.tertiary
                    : kit.colors.error,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      );
    }).toList();

    if (rows.isEmpty) {
      return AppCard(
        margin: kit.spacing.vSm,
        padding: kit.spacing.allLg,
        child: Center(
          child: BridgeText(
            "No accounts with balance.",
            style: kit.typography.body,
          ),
        ),
      );
    }
    return AppCard(
      margin: kit.spacing.vSm,
      padding: EdgeInsets.only(top: kit.spacing.md, bottom: kit.spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: kit.spacing.hLg,
            child: BridgeText('Asset Balances', style: kit.typography.headline),
          ),
          kit.spacing.gapSm,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: BridgeText(
                    'Account',
                    style: kit.typography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: BridgeText(
                    'Balance',
                    style: kit.typography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  numeric: true,
                ),
              ],
              rows: rows,
            ),
          ),
        ],
      ),
    );
  }
}
