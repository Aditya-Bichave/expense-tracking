// lib/features/reports/presentation/widgets/charts/spending_bar_chart.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpendingBarChart extends StatelessWidget {
  final List<CategorySpendingData> data;
  final List<CategorySpendingData>?
      previousData; // Now used for comparison display
  final Function(int index)? onTapBar;
  final int maxBarsToShow; // Renamed from `limit`

  const SpendingBarChart({
    super.key,
    required this.data,
    this.previousData,
    this.onTapBar,
    this.maxBarsToShow = 7,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final bool showComparison =
        previousData != null && previousData!.isNotEmpty;

    if (data.isEmpty) return const Center(child: Text("No data to display"));

    // Take limited data for display, but need full previous data for lookup
    final chartData = data.take(maxBarsToShow).toList();
    final Map<String, CategorySpendingData> previousDataMap = showComparison
        ? {for (var item in previousData!) item.categoryId: item}
        : {};

    double maxY = 0;
    for (var item in chartData) {
      if (item.currentTotalAmount > maxY) maxY = item.currentTotalAmount;
      if (showComparison && previousDataMap.containsKey(item.categoryId)) {
        final prevValue = previousDataMap[item.categoryId]!.currentTotalAmount;
        if (prevValue > maxY) maxY = prevValue;
      }
    }
    maxY = (maxY * 1.15).ceilToDouble();
    if (maxY <= 0) maxY = 10; // Ensure some height if all values are 0

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = chartData[groupIndex];
              final bool isPrevious = showComparison && rodIndex == 0;
              final value = isPrevious
                  ? item.totalAmount.previousValue ?? 0.0
                  : item.currentTotalAmount;
              final color = rod.color; // Use rod color
              final prefix = isPrevious ? "Prev " : "";

              return BarTooltipItem(
                '${item.categoryName}\n',
                ChartUtils.tooltipTitleStyle(context),
                children: <TextSpan>[
                  TextSpan(
                    text:
                        '$prefix${CurrencyFormatter.format(value, currencySymbol)}',
                    style:
                        ChartUtils.tooltipContentStyle(context, color: color),
                  ),
                ],
                textAlign: TextAlign.left,
              );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent &&
                barTouchResponse != null &&
                barTouchResponse.spot != null) {
              final index = barTouchResponse.spot!.touchedBarGroupIndex;
              onTapBar?.call(index); // Call the callback
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
              getTitlesWidget: (value, meta) => ChartUtils.bottomTitleWidgets(
                  context,
                  value,
                  meta,
                  chartData.length,
                  (index) => chartData[index].categoryName),
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) =>
                  ChartUtils.leftTitleWidgets(context, value, meta, maxY),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups:
            showingGroups(context, chartData, previousDataMap, showComparison),
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
      ),
    );
  }

  List<BarChartGroupData> showingGroups(
      BuildContext context,
      List<CategorySpendingData> chartData,
      Map<String, CategorySpendingData> previousDataMap,
      bool showComparison) {
    final double barWidth = showComparison ? 8 : 16;
    final double spaceBetweenRods = showComparison ? 2 : 0;

    return List.generate(chartData.length, (i) {
      final currentItem = chartData[i];
      final CategorySpendingData? prevItem =
          showComparison ? previousDataMap[currentItem.categoryId] : null;

      return BarChartGroupData(
        x: i,
        barsSpace: spaceBetweenRods,
        barRods: [
          // Previous Bar (if comparing) - Render first for background effect
          if (showComparison)
            BarChartRodData(
              toY: prevItem?.currentTotalAmount ?? 0,
              color:
                  currentItem.categoryColor.withOpacity(0.4), // Lighter color
              width: barWidth,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          // Current Bar
          BarChartRodData(
            toY: currentItem.currentTotalAmount,
            color: currentItem.categoryColor, // Solid color
            width: barWidth,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}
