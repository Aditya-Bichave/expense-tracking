// lib/features/reports/presentation/widgets/charts/income_expense_bar_chart.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/main.dart'; // Logger

class IncomeExpenseBarChart extends StatelessWidget {
  final List<IncomeExpensePeriodData> data;

  const IncomeExpenseBarChart({super.key, required this.data});

  // --- ADDED Drill Down Handler ---
  void _handleTap(BuildContext context, int groupIndex, int rodIndex) {
    if (groupIndex < 0 || groupIndex >= data.length) return;

    final tappedPeriod = data[groupIndex];
    final filterBlocState = context.read<ReportFilterBloc>().state;

    // Determine period start/end based on chart granularity
    DateTime periodStart = tappedPeriod.periodStart;
    DateTime periodEnd;
    final isMonthly = data.length > 1 &&
        data[1].periodStart.month != data[0].periodStart.month;
    final periodType = isMonthly
        ? IncomeExpensePeriodType.monthly
        : IncomeExpensePeriodType.yearly;

    if (periodType == IncomeExpensePeriodType.monthly) {
      periodEnd =
          DateTime(periodStart.year, periodStart.month + 1, 0, 23, 59, 59);
    } else {
      // Yearly
      periodEnd = DateTime(periodStart.year, 12, 31, 23, 59, 59);
    }

    // Determine type based on which bar was tapped (rodIndex 0=Income, 1=Expense)
    final transactionType =
        rodIndex == 0 ? TransactionType.income : TransactionType.expense;

    // Construct filter map compatible with TransactionListPage
    final Map<String, String> filters = {
      'startDate': periodStart.toIso8601String(),
      'endDate': periodEnd.toIso8601String(),
      'type': transactionType.name, // Filter by tapped type
    };
    // Include account filters if they were applied in the report filter
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }
    // Category filter usually doesn't apply to this report, but could be added if needed

    log.info(
        "[IncomeExpenseBarChart] Navigating to transactions with filters: $filters");
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }
  // --- END ADD ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final incomeColor = Colors.green.shade600;
    final expenseColor = theme.colorScheme.error;

    if (data.isEmpty) {
      return const Center(child: Text("No data to display"));
    }

    double maxY = 0;
    for (var item in data) {
      if (item.totalIncome > maxY) maxY = item.totalIncome;
      if (item.totalExpense > maxY) maxY = item.totalExpense;
    }
    maxY = (maxY * 1.15).ceilToDouble();

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
              final rodColor = rod.color;
              final value = rod.toY;
              String type = rodColor == incomeColor ? "Income" : "Expense";

              return BarTooltipItem(
                  '$periodStr\n', ChartUtils.tooltipTitleStyle(context),
                  children: <TextSpan>[
                    TextSpan(
                        text:
                            '$type: ${CurrencyFormatter.format(value, currencySymbol)}',
                        style: ChartUtils.tooltipContentStyle(context,
                            color: rodColor))
                  ]);
            },
          ),
          // --- ADDED Touch Callback ---
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent &&
                barTouchResponse != null &&
                barTouchResponse.spot != null) {
              final groupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              final rodIndex = barTouchResponse.spot!.touchedRodDataIndex;
              _handleTap(context, groupIndex, rodIndex);
            }
          },
          // --- END ADD ---
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
                getTitlesWidget: (value, meta) =>
                    ChartUtils.leftTitleWidgets(context, value, meta, maxY)),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: showingGroups(context, data, incomeColor, expenseColor),
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
      ),
    );
  }

  List<BarChartGroupData> showingGroups(
      BuildContext context,
      List<IncomeExpensePeriodData> data,
      Color incomeColor,
      Color expenseColor) {
    final double groupSpace = 4; // Space between income/expense bars
    final double barWidth = 10; // Adjust width

    return List.generate(data.length, (i) {
      final item = data[i];
      return BarChartGroupData(
        x: i,
        barsSpace: groupSpace,
        barRods: [
          BarChartRodData(
            toY: item.totalIncome,
            color: incomeColor,
            width: barWidth,
            borderRadius: BorderRadius.zero,
          ),
          BarChartRodData(
            toY: item.totalExpense,
            color: expenseColor,
            width: barWidth,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });
  }

  // --- Helper Methods (_formatPeriodHeader, _bottomTitleWidgets) unchanged ---
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
    if (index < 0 || index >= data.length) return const SizedBox.shrink();
    final date = data[index].periodStart;
    String text;
    switch (periodType) {
      case IncomeExpensePeriodType.monthly:
        text = DateFormat('MMM').format(date);
        if (date.month == 1 || index == 0) {
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
