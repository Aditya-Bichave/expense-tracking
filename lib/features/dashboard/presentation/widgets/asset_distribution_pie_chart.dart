import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:flutter_bloc/flutter_bloc.dart'; // To read settings
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/core/utils/color_utils.dart';

class AssetDistributionPieChart extends StatefulWidget {
  final List<AssetAccount> accounts;

  const AssetDistributionPieChart({super.key, required this.accounts});

  @override
  State<StatefulWidget> createState() => AssetDistributionPieChartState();
}

class AssetDistributionPieChartState extends State<AssetDistributionPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final uiMode = settingsState.uiMode;

    log.info(
        "[PieChart] Build method. TouchedIndex: $touchedIndex, Mode: $uiMode");

    // --- Quantum Mode: Return null, handled by DashboardPage ---
    // Note: We could render a table here, but dashboard page already does
    if (uiMode == UIMode.quantum) {
      log.info("[PieChart] Quantum mode active. Returning SizedBox.shrink().");
      return const SizedBox.shrink(); // Dashboard page handles Quantum display
    }
    // --- End Quantum Mode Handling ---

    // Filter out accounts with zero or negative balance for the chart itself
    final positiveAccounts =
        widget.accounts.where((acc) => acc.currentBalance > 0).toList();

    log.info(
        "[PieChart] Filtered positive balances: ${positiveAccounts.length} accounts.");

    if (positiveAccounts.isEmpty) {
      log.info("[PieChart] No positive balances to display.");
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
              child: Text('No positive asset balances to chart.',
                  style: theme.textTheme.bodyMedium)),
        ),
      );
    }

    final double totalPositiveBalance = positiveAccounts.fold(
        0.0, (sum, acc) => sum + acc.currentBalance);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asset Distribution',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.4,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          if (touchedIndex != -1) {
                            touchedIndex = -1;
                          }
                          return;
                        }
                        touchedIndex =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: showingSections(
                      positiveAccounts, totalPositiveBalance, theme),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: positiveAccounts.map((account) {
                return _buildLegend(
                    account.name, ColorUtils.fromHex(account.colorHex), theme);
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String name, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(name, style: theme.textTheme.bodySmall),
      ],
    );
  }

  List<PieChartSectionData> showingSections(List<AssetAccount> accounts,
      double totalValue, ThemeData theme) {
    return List.generate(accounts.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 15.0 : 11.0;
      final radius = isTouched ? 70.0 : 60.0;
      final account = accounts[i];
      final color = ColorUtils.fromHex(account.colorHex);
      final percentage =
          totalValue > 0 ? (account.currentBalance / totalValue * 100) : 0.0;
      final titleColor =
          color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

      return PieChartSectionData(
        color: color,
        value: account.currentBalance,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: titleColor,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        borderSide: isTouched
            ? BorderSide(color: theme.colorScheme.surface, width: 2)
            : BorderSide(color: color.withAlpha(0)),
      );
    });
  }
}
