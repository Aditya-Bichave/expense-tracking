// lib/features/reports/presentation/widgets/charts/budget_performance_bar_chart.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BudgetPerformanceBarChart extends StatelessWidget {
  final List<BudgetPerformanceData> data;
  final List<BudgetPerformanceData>? previousData; // Null if not comparing
  final String currencySymbol;
  final Function(int index)? onTapBar;
  final int maxBarsToShow; // Limit bars

  const BudgetPerformanceBarChart({
    super.key,
    required this.data,
    this.previousData,
    required this.currencySymbol,
    this.onTapBar,
    this.maxBarsToShow = 7, // Default limit
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool showComparison =
        previousData != null && previousData!.isNotEmpty;

    if (data.isEmpty) {
      return const Center(child: Text("No budget data to display"));
    }

    // Take limited data for display, but need full previous data for lookup
    final chartData = data.take(maxBarsToShow).toList();
    final Map<String, BudgetPerformanceData> previousDataMap = showComparison
        ? {for (var item in previousData!) item.budget.id: item}
        : {};

    double maxY = 0;
    for (var item in chartData) {
      if (item.budget.targetAmount > maxY) {
        maxY = item.budget.targetAmount;
      }
      if (item.currentActualSpending > maxY) {
        maxY = item.currentActualSpending;
      }
      if (showComparison && previousDataMap.containsKey(item.budget.id)) {
        final prevItem = previousDataMap[item.budget.id]!;
        if (prevItem.budget.targetAmount > maxY) {
          maxY = prevItem.budget.targetAmount;
        }
        if (prevItem.currentActualSpending > maxY) {
          maxY = prevItem.currentActualSpending;
        }
      }
    }
    maxY = (maxY * 1.15).ceilToDouble();
    if (maxY <= 0) {
      maxY = 10; // Ensure some height
    }

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final currentItem = chartData[groupIndex];
              final budget = currentItem.budget;
              final BudgetPerformanceData? prevItem =
                  showComparison ? previousDataMap[budget.id] : null;
              bool isTargetBar;
              bool isPreviousBar;
              double value;
              Color color;

              // Determine which bar was touched
              if (showComparison) {
                // Order: PrevTarget, CurrTarget, PrevActual, CurrActual
                if (rodIndex == 0) {
                  isTargetBar = true;
                  isPreviousBar = true;
                  value = prevItem?.budget.targetAmount ?? 0;
                  color = rod.color ?? Colors.grey;
                } else if (rodIndex == 1) {
                  isTargetBar = true;
                  isPreviousBar = false;
                  value = budget.targetAmount;
                  color = rod.color ?? Colors.grey;
                } else if (rodIndex == 2) {
                  isTargetBar = false;
                  isPreviousBar = true;
                  value = prevItem?.currentActualSpending ?? 0;
                  color = rod.color ?? Colors.grey;
                } else /* rodIndex == 3 */ {
                  isTargetBar = false;
                  isPreviousBar = false;
                  value = currentItem.currentActualSpending;
                  color = rod.color ?? Colors.grey;
                }
              } else {
                // Order: CurrTarget, CurrActual
                if (rodIndex == 0) {
                  isTargetBar = true;
                  isPreviousBar = false;
                  value = budget.targetAmount;
                  color = rod.color ?? Colors.grey;
                } else /* rodIndex == 1 */ {
                  isTargetBar = false;
                  isPreviousBar = false;
                  value = currentItem.currentActualSpending;
                  color = rod.color ?? Colors.grey;
                }
              }

              final tooltipMainText = isTargetBar ? 'Target' : 'Actual';
              final tooltipPrefix = isPreviousBar ? 'Prev ' : '';

              return BarTooltipItem(
                '${budget.name}\n',
                ChartUtils.tooltipTitleStyle(context),
                children: <TextSpan>[
                  TextSpan(
                    text:
                        '$tooltipPrefix$tooltipMainText: ${CurrencyFormatter.format(value, currencySymbol)}',
                    style:
                        ChartUtils.tooltipContentStyle(context, color: color),
                  ),
                  // Optionally add variance info
                  if (!isTargetBar) // Show variance only for Actual bars
                    TextSpan(
                        text:
                            '\nVar: ${CurrencyFormatter.format(currentItem.currentVarianceAmount, currencySymbol)} (${currentItem.currentVariancePercent.toStringAsFixed(0)}%)',
                        style: ChartUtils.tooltipContentStyle(context,
                                color: currentItem.statusColor)
                            .copyWith(fontSize: 11))
                ],
                textAlign: TextAlign.left,
              );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (onTapBar != null &&
                event is FlTapUpEvent &&
                barTouchResponse != null &&
                barTouchResponse.spot != null) {
              final index = barTouchResponse.spot!.touchedBarGroupIndex;
              onTapBar!(index);
            }
          },
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
                    getTitlesWidget: (value, meta) =>
                        ChartUtils.bottomTitleWidgets(
                            context,
                            value,
                            meta,
                            chartData.length,
                            (index) => chartData[index].budget.name),
                    reservedSize: 38)),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    interval: maxY / 5, // Match grid
                    getTitlesWidget: (value, meta) =>
                        ChartUtils.leftTitleWidgets(
                            context, value, meta, maxY)))),
        borderData: FlBorderData(show: false),
        barGroups:
            showingGroups(context, chartData, previousDataMap, showComparison),
        gridData: FlGridData(
          // Subtle grid
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.1), strokeWidth: 1),
        ),
        alignment: BarChartAlignment.spaceAround,
      ),
    );
  }

  List<BarChartGroupData> showingGroups(
      BuildContext context,
      List<BudgetPerformanceData> chartData,
      Map<String, BudgetPerformanceData> previousDataMap,
      bool showComparison) {
    final theme = Theme.of(context);
    final double barWidth = showComparison ? 6 : 12; // Narrower bars
    final double groupSpace = showComparison ? 1 : 4; // Space between rods

    return List.generate(chartData.length, (i) {
      final currentItem = chartData[i];
      final budget = currentItem.budget;
      final BudgetPerformanceData? prevItem =
          showComparison ? previousDataMap[budget.id] : null;
      final targetColor =
          theme.colorScheme.secondary; // Use secondary for target
      final actualColor = currentItem.statusColor;
      final prevTargetColor = targetColor.withOpacity(0.4);
      final prevActualColor = actualColor.withOpacity(0.4);

      return BarChartGroupData(
        x: i,
        barsSpace: groupSpace,
        barRods: [
          // Previous Target (if comparing)
          if (showComparison)
            BarChartRodData(
              toY: prevItem?.budget.targetAmount ?? 0,
              color: prevTargetColor,
              width: barWidth,
              borderRadius: BorderRadius.zero,
            ),
          // Current Target
          BarChartRodData(
            toY: budget.targetAmount,
            color: targetColor,
            width: barWidth,
            borderRadius: BorderRadius.zero,
          ),
          // Previous Actual (if comparing)
          if (showComparison)
            BarChartRodData(
              toY: prevItem?.currentActualSpending ?? 0,
              color: prevActualColor,
              width: barWidth,
              borderRadius: BorderRadius.zero,
            ),
          // Current Actual
          BarChartRodData(
            toY: currentItem.currentActualSpending,
            color: actualColor,
            width: barWidth,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });
  }
}
