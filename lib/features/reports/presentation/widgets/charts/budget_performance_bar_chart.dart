// lib/features/reports/presentation/widgets/charts/budget_performance_bar_chart.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For NumberFormat

class BudgetPerformanceBarChart extends StatelessWidget {
  final List<BudgetPerformanceData> data;
  final List<BudgetPerformanceData>? previousData; // For comparison
  final String currencySymbol;

  const BudgetPerformanceBarChart({
    super.key,
    required this.data,
    this.previousData,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool showComparison = previousData != null;

    if (data.isEmpty) {
      return const Center(child: Text("No budget data to display"));
    }

    // Find max Y value for scaling across both current and previous data
    double maxY = 0;
    final Map<String, BudgetPerformanceData> previousDataMap = showComparison
        ? {for (var item in previousData!) item.budget.id: item}
        : {};

    for (var item in data) {
      if (item.budget.targetAmount > maxY) maxY = item.budget.targetAmount;
      if (item.actualSpending > maxY) maxY = item.actualSpending;
      if (showComparison && previousDataMap.containsKey(item.budget.id)) {
        final prevItem = previousDataMap[item.budget.id]!;
        if (prevItem.budget.targetAmount > maxY)
          maxY = prevItem.budget.targetAmount;
        if (prevItem.actualSpending > maxY) maxY = prevItem.actualSpending;
      }
    }
    maxY = (maxY * 1.15).ceilToDouble(); // Add padding

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[groupIndex];
              final budget = item.budget;
              String title = '${budget.name}\n';
              final BudgetPerformanceData? prevItem =
                  showComparison ? previousDataMap[budget.id] : null;

              // Determine which bar was touched based on rodIndex and showComparison
              bool isTargetBar = false;
              bool isPreviousBar = false;
              if (showComparison) {
                if (rodIndex == 0) {
                  isTargetBar = true;
                  isPreviousBar = true;
                } else if (rodIndex == 1) {
                  isTargetBar = true;
                  isPreviousBar = false;
                } else if (rodIndex == 2) {
                  isTargetBar = false;
                  isPreviousBar = true;
                } else {
                  isTargetBar = false;
                  isPreviousBar = false;
                }
              } else {
                if (rodIndex == 0) {
                  isTargetBar = true;
                } else {
                  isTargetBar = false;
                }
              }

              final displayValue = isPreviousBar
                  ? (isTargetBar
                          ? prevItem?.budget.targetAmount
                          : prevItem?.actualSpending) ??
                      0.0
                  : (isTargetBar ? budget.targetAmount : item.actualSpending);
              final displayColor = isPreviousBar
                  ? (isTargetBar
                      ? theme.colorScheme.secondary.withOpacity(0.3)
                      : item.statusColor.withOpacity(0.4))
                  : (isTargetBar
                      ? theme.colorScheme.secondary.withOpacity(0.8)
                      : item.statusColor);

              final tooltipMainText = isTargetBar ? 'Target' : 'Actual';
              final tooltipPrefix = isPreviousBar ? 'Prev ' : '';

              List<TextSpan> children = [
                TextSpan(
                    text:
                        '$tooltipPrefix$tooltipMainText: ${CurrencyFormatter.format(displayValue, currencySymbol)}',
                    style: ChartUtils.tooltipContentStyle(context,
                        color: displayColor))
              ];

              // Add the other value (current/previous) for comparison if showing comparison
              if (showComparison && prevItem != null) {
                final otherValue = !isPreviousBar
                    ? (isTargetBar
                        ? prevItem.budget.targetAmount
                        : prevItem.actualSpending)
                    : (isTargetBar ? budget.targetAmount : item.actualSpending);
                final otherColor = !isPreviousBar
                    ? (isTargetBar
                        ? theme.colorScheme.secondary.withOpacity(0.3)
                        : item.statusColor.withOpacity(0.4))
                    : (isTargetBar
                        ? theme.colorScheme.secondary.withOpacity(0.8)
                        : item.statusColor);
                final otherPrefix = !isPreviousBar ? 'Prev ' : '';

                children.add(const TextSpan(text: '\n'));
                children.add(TextSpan(
                    text:
                        '$otherPrefix$tooltipMainText: ${CurrencyFormatter.format(otherValue, currencySymbol)}',
                    style: ChartUtils.tooltipContentStyle(context,
                        color:
                            otherColor?.withOpacity(0.7)) // Dim the other value
                    ));
              }

              return BarTooltipItem(
                  title, ChartUtils.tooltipTitleStyle(context),
                  children: children, textAlign: TextAlign.left);
            },
          ),
          // TODO: Add touch callback for drill-down if needed
          // touchCallback: ...
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => ChartUtils.bottomTitleWidgets(
                  context,
                  value,
                  meta,
                  data.length,
                  (index) => data[index].budget.name), // Show budget name
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) =>
                    ChartUtils.leftTitleWidgets(context, value, meta, maxY)),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups:
            showingGroups(context, data, previousDataMap, showComparison),
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround, // Space between budget groups
      ),
    );
  }

  List<BarChartGroupData> showingGroups(
      BuildContext context,
      List<BudgetPerformanceData> data,
      Map<String, BudgetPerformanceData> previousDataMap,
      bool showComparison) {
    final theme = Theme.of(context);
    final double barWidth =
        showComparison ? 8 : 16; // Narrower bars for comparison
    final double spaceBetweenRods =
        showComparison ? 1 : 0; // Small space when comparing

    return List.generate(data.length, (i) {
      final currentItem = data[i];
      final budget = currentItem.budget;
      final BudgetPerformanceData? prevItem =
          showComparison ? previousDataMap[budget.id] : null;

      final targetColor = theme.colorScheme.secondary.withOpacity(0.8);
      final actualColor = currentItem.statusColor;
      final prevTargetColor = targetColor.withOpacity(0.3);
      final prevActualColor = actualColor.withOpacity(0.4);

      return BarChartGroupData(
        x: i,
        barsSpace: spaceBetweenRods,
        barRods: [
          // Order: PrevTarget, CurrTarget, PrevActual, CurrActual (if comparing)
          // Order: CurrTarget, CurrActual (if not comparing)

          if (showComparison)
            BarChartRodData(
              toY: prevItem?.budget.targetAmount ?? 0,
              color: prevTargetColor,
              width: barWidth,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          BarChartRodData(
            toY: budget.targetAmount,
            color: targetColor,
            width: barWidth,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
          if (showComparison)
            BarChartRodData(
              toY: prevItem?.actualSpending ?? 0,
              color: prevActualColor,
              width: barWidth,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          BarChartRodData(
            toY: currentItem.actualSpending,
            color: actualColor,
            width: barWidth,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}
