// lib/features/reports/presentation/widgets/charts/time_series_line_chart.dart
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

class TimeSeriesLineChart extends StatelessWidget {
  final List<TimeSeriesDataPoint> data;
  final TimeSeriesGranularity granularity;

  const TimeSeriesLineChart({
    super.key,
    required this.data,
    required this.granularity,
  });

  // --- ADDED Drill Down Handler ---
  void _handleTap(BuildContext context, int spotIndex) {
    if (spotIndex < 0 || spotIndex >= data.length) return;

    final tappedPoint = data[spotIndex];
    final filterBlocState = context.read<ReportFilterBloc>().state;

    // Calculate start and end dates for the tapped period
    DateTime periodStart;
    DateTime periodEnd;

    switch (granularity) {
      case TimeSeriesGranularity.daily:
        periodStart = tappedPoint.date;
        periodEnd = DateTime(tappedPoint.date.year, tappedPoint.date.month,
            tappedPoint.date.day, 23, 59, 59);
        break;
      case TimeSeriesGranularity.weekly:
        periodStart = tappedPoint.date; // Already the start of the week
        periodEnd = periodStart
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case TimeSeriesGranularity.monthly:
        periodStart = tappedPoint.date; // Already the start of the month
        periodEnd = DateTime(
            tappedPoint.date.year, tappedPoint.date.month + 1, 0, 23, 59, 59);
        break;
    }

    // Construct filter map compatible with TransactionListPage
    final Map<String, String> filters = {
      'startDate': periodStart.toIso8601String(),
      'endDate': periodEnd.toIso8601String(),
      'type': TransactionType.expense.name, // This chart shows expenses
    };
    // Include account/category filters if they were applied in the report filter
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }
    if (filterBlocState.selectedCategoryIds.isNotEmpty) {
      filters['categoryId'] = filterBlocState.selectedCategoryIds.join(',');
    }

    log.info(
        "[TimeSeriesLineChart] Navigating to transactions with filters: $filters");
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }
  // --- END ADD ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final primaryColor = theme.colorScheme.primary;

    if (data.isEmpty) {
      return const Center(child: Text("No data to display"));
    }

    double minY = 0;
    double maxY = 0;
    double minX = data.first.date.millisecondsSinceEpoch.toDouble();
    double maxX = data.last.date.millisecondsSinceEpoch.toDouble();
    for (var point in data) {
      if (point.amount > maxY) maxY = point.amount;
    }
    maxY = (maxY * 1.15).ceilToDouble();

    final List<FlSpot> spots = data
        .map((point) =>
            FlSpot(point.date.millisecondsSinceEpoch.toDouble(), point.amount))
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateXInterval(minX, maxX, granularity),
              getTitlesWidget: (value, meta) =>
                  _bottomTitleWidgets(context, value, meta, granularity),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) =>
                  ChartUtils.leftTitleWidgets(context, value, meta, maxY),
            ),
          ),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.dividerColor, width: 0.5)),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [
                  primaryColor.withOpacity(0.3),
                  primaryColor.withOpacity(0.0)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final date =
                    DateTime.fromMillisecondsSinceEpoch(barSpot.x.toInt());
                final amount = barSpot.y;
                final dateStr = _formatTooltipDate(date, granularity);
                return LineTooltipItem(
                    '$dateStr\n', ChartUtils.tooltipTitleStyle(context),
                    children: <TextSpan>[
                      TextSpan(
                          text:
                              CurrencyFormatter.format(amount, currencySymbol),
                          style: ChartUtils.tooltipContentStyle(context,
                              color: primaryColor))
                    ]);
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          // --- ADDED Touch Callback ---
          touchCallback:
              (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (event is FlTapUpEvent &&
                touchResponse != null &&
                touchResponse.lineBarSpots != null &&
                touchResponse.lineBarSpots!.isNotEmpty) {
              final spotIndex = touchResponse.lineBarSpots![0].spotIndex;
              _handleTap(context, spotIndex);
            }
          },
          // --- END ADD ---
        ),
      ),
    );
  }

  // --- Helper methods (_calculateXInterval, _formatTooltipDate, _bottomTitleWidgets) unchanged ---
  double? _calculateXInterval(
      double minX, double maxX, TimeSeriesGranularity granularity) {
    final durationMs = maxX - minX;
    if (durationMs <= 0) return null;

    switch (granularity) {
      case TimeSeriesGranularity.daily:
        final days = durationMs / Duration.millisecondsPerDay;
        return days > 6 ? durationMs / 6 : null;
      case TimeSeriesGranularity.weekly:
        final weeks = durationMs / (Duration.millisecondsPerDay * 7);
        return weeks > 5 ? durationMs / 5 : null;
      case TimeSeriesGranularity.monthly:
        final months = durationMs / (Duration.millisecondsPerDay * 30.44);
        return months > 5 ? durationMs / 5 : null;
    }
  }

  String _formatTooltipDate(DateTime date, TimeSeriesGranularity granularity) {
    switch (granularity) {
      case TimeSeriesGranularity.daily:
        return DateFormat('E, MMM d').format(date);
      case TimeSeriesGranularity.weekly:
        return 'Week of ${DateFormat.MMMd().format(date)}';
      case TimeSeriesGranularity.monthly:
        return DateFormat('MMM yyyy').format(date);
    }
  }

  Widget _bottomTitleWidgets(BuildContext context, double value, TitleMeta meta,
      TimeSeriesGranularity granularity) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(fontSize: 10);
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    String text;

    switch (granularity) {
      case TimeSeriesGranularity.daily:
        text = DateFormat('d').format(date);
        if (date.day == 1 || value == meta.min) {
          text = '${DateFormat('MMM').format(date)}\n$text';
        }
        break;
      case TimeSeriesGranularity.weekly:
        text = DateFormat('d').format(date);
        if (date.day <= 7 || value == meta.min) {
          text = '${DateFormat('MMM').format(date)}\n$text';
        }
        break;
      case TimeSeriesGranularity.monthly:
        text = DateFormat('MMM').format(date);
        if (date.month == 1 || value == meta.min) {
          text = '${DateFormat('yy').format(date)}\n$text';
        }
        break;
    }
    return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text(text, style: style, textAlign: TextAlign.center));
  }
}
