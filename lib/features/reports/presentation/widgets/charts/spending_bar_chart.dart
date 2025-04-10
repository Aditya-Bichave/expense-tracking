// lib/features/reports/presentation/widgets/charts/spending_bar_chart.dart
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
import 'package:expense_tracker/main.dart';

class SpendingBarChart extends StatelessWidget {
  final List<CategorySpendingData> data;
  final int maxBarsToShow;

  const SpendingBarChart({
    super.key,
    required this.data,
    this.maxBarsToShow = 7,
  });

  void _handleTap(BuildContext context, int index) {
    if (index < 0 || index >= data.length) return;
    final tappedItem = data[index];
    final filterBlocState = context.read<ReportFilterBloc>().state;

    // Construct filter map compatible with TransactionListPage
    final Map<String, String> filters = {
      'startDate': filterBlocState.startDate.toIso8601String(),
      'endDate': filterBlocState.endDate.toIso8601String(),
      'type': TransactionType.expense.name,
      'categoryId': tappedItem.categoryId, // Filter by tapped category
    };
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }

    log.info(
        "[SpendingBarChart] Navigating to transactions with filters: $filters");
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;

    if (data.isEmpty) {
      return const Center(child: Text("No data to display"));
    }

    final chartData = data.take(maxBarsToShow).toList();
    double maxY = 0;
    for (var item in chartData) {
      if (item.totalAmount > maxY) maxY = item.totalAmount;
    }
    maxY = (maxY * 1.15).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = chartData[groupIndex];
              return BarTooltipItem(
                '${item.categoryName}\n',
                ChartUtils.tooltipTitleStyle(context),
                children: <TextSpan>[
                  TextSpan(
                    text: CurrencyFormatter.format(
                        item.totalAmount, currencySymbol),
                    style: ChartUtils.tooltipContentStyle(context,
                        color: item.categoryColor),
                  ),
                ],
              );
            },
          ),
          // --- ADDED Touch Callback for Drill-down ---
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent &&
                barTouchResponse != null &&
                barTouchResponse.spot != null) {
              final index = barTouchResponse.spot!.touchedBarGroupIndex;
              _handleTap(context, index);
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
        barGroups: showingGroups(context, chartData),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  List<BarChartGroupData> showingGroups(
      BuildContext context, List<CategorySpendingData> chartData) {
    // final theme = Theme.of(context); // Not needed here anymore
    return List.generate(chartData.length, (i) {
      final item = chartData[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: item.totalAmount,
            color: item.categoryColor,
            width: 16,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}
