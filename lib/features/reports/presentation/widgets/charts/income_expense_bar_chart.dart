// lib/features/reports/presentation/widgets/charts/income_expense_bar_chart.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  final List<IncomeExpensePeriodData> data;
  final bool showComparison;
  final Function(int groupIndex, int rodIndex)? onTapBar;

  const IncomeExpenseBarChart({
    super.key,
    required this.data,
    this.showComparison = false,
    this.onTapBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final incomeColor = Colors.green.shade600; // Consistent Income color
    final expenseColor = theme.colorScheme.error;
    final prevIncomeColor =
        incomeColor.withAlpha((255 * 0.4).round()); // Lighter for previous
    final prevExpenseColor =
        expenseColor.withAlpha((255 * 0.4).round()); // Lighter for previous

    if (data.isEmpty) return const Center(child: Text("No data to display"));

    double maxY = 0;
    for (var item in data) {
      if (item.currentTotalIncome > maxY) maxY = item.currentTotalIncome;
      if (item.currentTotalExpense > maxY) maxY = item.currentTotalExpense;
      if (showComparison) {
        if (item.totalIncome.previousValue != null &&
            item.totalIncome.previousValue! > maxY)
          maxY = item.totalIncome.previousValue!;
        if (item.totalExpense.previousValue != null &&
            item.totalExpense.previousValue! > maxY)
          maxY = item.totalExpense.previousValue!;
      }
    }
    maxY = (maxY * 1.15).ceilToDouble();
    if (maxY <= 0) maxY = 10; // Ensure some height

    final isMonthly = data.length > 1 &&
        data[1].periodStart.month != data[0].periodStart.month;
    final periodType = isMonthly
        ? IncomeExpensePeriodType.monthly
        : IncomeExpensePeriodType.yearly;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[groupIndex];
              final periodStr =
                  _formatPeriodHeader(item.periodStart, periodType);
              bool isIncome;
              bool isPrevious;
              double value;
              Color color;

              // Determine which bar was touched based on rodIndex and showComparison
              if (showComparison) {
                // Order: PrevIncome, CurrIncome, PrevExpense, CurrExpense
                if (rodIndex == 0) {
                  isIncome = true;
                  isPrevious = true;
                  value = item.totalIncome.previousValue ?? 0;
                  color = prevIncomeColor;
                } else if (rodIndex == 1) {
                  isIncome = true;
                  isPrevious = false;
                  value = item.currentTotalIncome;
                  color = incomeColor;
                } else if (rodIndex == 2) {
                  isIncome = false;
                  isPrevious = true;
                  value = item.totalExpense.previousValue ?? 0;
                  color = prevExpenseColor;
                } else /* rodIndex == 3 */ {
                  isIncome = false;
                  isPrevious = false;
                  value = item.currentTotalExpense;
                  color = expenseColor;
                }
              } else {
                // Order: CurrIncome, CurrExpense
                if (rodIndex == 0) {
                  isIncome = true;
                  isPrevious = false;
                  value = item.currentTotalIncome;
                  color = incomeColor;
                } else /* rodIndex == 1 */ {
                  isIncome = false;
                  isPrevious = false;
                  value = item.currentTotalExpense;
                  color = expenseColor;
                }
              }

              final prefix = isPrevious ? "Prev " : "";
              final typeStr = isIncome ? "Income" : "Expense";

              return BarTooltipItem(
                '$periodStr\n',
                ChartUtils.tooltipTitleStyle(context),
                children: <TextSpan>[
                  TextSpan(
                    text:
                        '$prefix$typeStr: ${CurrencyFormatter.format(value, currencySymbol)}',
                    style:
                        ChartUtils.tooltipContentStyle(context, color: color),
                  ),
                  // Optionally show net flow for the group in tooltip
                  // TextSpan(text: '\nNet: ${CurrencyFormatter.format(item.currentNetFlow, currencySymbol)}', style: TextStyle(...))
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
              final groupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              final rodIndex = barTouchResponse.spot!.touchedRodDataIndex;
              onTapBar!(groupIndex, rodIndex);
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
                  _bottomTitleWidgets(context, value, meta, periodType, data),
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: maxY / 5, // Match grid interval if shown
              getTitlesWidget: (value, meta) =>
                  ChartUtils.leftTitleWidgets(context, value, meta, maxY),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: showingGroups(context, data, incomeColor, expenseColor,
            prevIncomeColor, prevExpenseColor, showComparison),
        gridData: FlGridData(
          // Subtle grid lines
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withAlpha((255 * 0.1).round()), strokeWidth: 1),
        ),
        alignment: BarChartAlignment.spaceAround,
      ),
    );
  }

  List<BarChartGroupData> showingGroups(
      BuildContext context,
      List<IncomeExpensePeriodData> data,
      Color incomeColor,
      Color expenseColor,
      Color prevIncomeColor,
      Color prevExpenseColor,
      bool showComparison) {
    final double barWidth = showComparison ? 6 : 12;
    final double groupSpace =
        showComparison ? 2 : 4; // Space between rods within a group

    return List.generate(data.length, (i) {
      final item = data[i];
      return BarChartGroupData(
        x: i,
        barsSpace: groupSpace,
        barRods: [
          // Previous Income (if comparing)
          if (showComparison)
            BarChartRodData(
                toY: item.totalIncome.previousValue ?? 0,
                color: prevIncomeColor,
                width: barWidth,
                borderRadius: BorderRadius.zero),
          // Current Income
          BarChartRodData(
              toY: item.currentTotalIncome,
              color: incomeColor,
              width: barWidth,
              borderRadius: BorderRadius.zero),
          // Previous Expense (if comparing)
          if (showComparison)
            BarChartRodData(
                toY: item.totalExpense.previousValue ?? 0,
                color: prevExpenseColor,
                width: barWidth,
                borderRadius: BorderRadius.zero),
          // Current Expense
          BarChartRodData(
              toY: item.currentTotalExpense,
              color: expenseColor,
              width: barWidth,
              borderRadius: BorderRadius.zero),
        ],
      );
    });
  }

  // Helper methods remain unchanged
  String _formatPeriodHeader(
      DateTime date, IncomeExpensePeriodType periodType) {
    switch (periodType) {
      case IncomeExpensePeriodType.monthly:
        return DateFormat('MMM yyyy').format(date);
      case IncomeExpensePeriodType.yearly:
        return DateFormat('yyyy').format(date);
    }
  }

  Widget _bottomTitleWidgets(BuildContext context, double value, TitleMeta meta,
      IncomeExpensePeriodType periodType, List<IncomeExpensePeriodData> data) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(fontSize: 10);
    final index = value.toInt();

    if (index < 0 || index >= data.length) {
      return const SizedBox.shrink(); // Avoid errors for invalid indices
    }
    final date = data[index].periodStart;

    String text;
    switch (periodType) {
      case IncomeExpensePeriodType.monthly:
        text = DateFormat('MMM').format(date);
        // Add year label conditionally to avoid clutter
        if (date.month == 1 ||
            index == 0 ||
            (index > 0 && data[index - 1].periodStart.year != date.year)) {
          text = '${DateFormat('yy').format(date)}\n$text';
        }
        break;
      case IncomeExpensePeriodType.yearly:
        text = DateFormat('yyyy').format(date);
        break;
    }

    return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text(text, style: style, textAlign: TextAlign.center));
  }
}
