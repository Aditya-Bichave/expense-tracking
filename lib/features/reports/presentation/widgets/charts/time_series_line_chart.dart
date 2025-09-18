// lib/features/reports/presentation/widgets/charts/time_series_line_chart.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TimeSeriesLineChart extends StatelessWidget {
  final List<TimeSeriesDataPoint> data;
  final TimeSeriesGranularity granularity;
  final bool showComparison;
  final Function(int index)? onTapSpot;

  const TimeSeriesLineChart({
    super.key,
    required this.data,
    required this.granularity,
    this.showComparison = false,
    this.onTapSpot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final primaryColor = theme.colorScheme.primary;
    final comparisonColor =
        theme.colorScheme.secondary.withOpacity(0.6); // Lighter/dashed color

    if (data.isEmpty) {
      return const Center(child: Text("No data to display"));
    }

    // Find min/max for axis scaling, considering both current and previous values
    double minY = 0;
    double maxY = 0;
    double minX = data.first.date.millisecondsSinceEpoch.toDouble();
    double maxX = data.last.date.millisecondsSinceEpoch.toDouble();

    for (var point in data) {
      if (point.currentAmount > maxY) maxY = point.currentAmount;
      if (showComparison &&
          point.amount.previousValue != null &&
          point.amount.previousValue! > maxY) {
        maxY = point.amount.previousValue!;
      }
    }
    maxY = (maxY * 1.15).ceilToDouble(); // Add padding
    if (maxY <= 0) maxY = 10; // Ensure some height if all values are 0

    // Create spots for current period
    final List<FlSpot> currentSpots = data
        .map((point) => FlSpot(
              point.date.millisecondsSinceEpoch.toDouble(),
              point.currentAmount, // Use getter
            ))
        .toList();

    // Create spots for previous period if showing comparison
    final List<FlSpot> previousSpots = (showComparison)
        ? data
            .where((p) =>
                p.amount.previousValue !=
                null) // Filter out points without previous data
            .map((point) => FlSpot(point.date.millisecondsSinceEpoch.toDouble(),
                point.amount.previousValue!))
            .toList()
        : [];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          // Subtle grid lines
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5, // Match left title intervals
          getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.1), strokeWidth: 1),
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
              interval: maxY / 5, // Match grid interval
              getTitlesWidget: (value, meta) =>
                  ChartUtils.leftTitleWidgets(context, value, meta, maxY),
            ),
          ),
        ),
        borderData: FlBorderData(show: false), // Hide outer border
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          // Current Period Line
          LineChartBarData(
            spots: currentSpots,
            isCurved: true,
            gradient: LinearGradient(
              // Use gradient for primary line
              colors: [primaryColor.withOpacity(0.8), primaryColor],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
                show: currentSpots.length < 30), // Show dots if few points
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.3),
                  primaryColor.withOpacity(0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Previous Period Line (dashed/lighter)
          if (showComparison && previousSpots.isNotEmpty)
            LineChartBarData(
              spots: previousSpots,
              isCurved: true,
              color: comparisonColor, // Use comparison color
              barWidth: 2,
              isStrokeCapRound: true,
              dotData:
                  const FlDotData(show: false), // Hide dots for comparison line
              dashArray: [4, 4], // Make it dashed
              belowBarData: BarAreaData(show: false), // No area fill
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              // Group spots by their x value (date)
              final Map<double, List<LineBarSpot>> spotsByX = {};
              for (var spot in touchedBarSpots) {
                spotsByX.putIfAbsent(spot.x, () => []).add(spot);
              }

              // Create one tooltip item per date, showing both values if comparing
              return spotsByX.entries.map((entry) {
                final xValue = entry.key;
                final spots = entry.value;
                final date =
                    DateTime.fromMillisecondsSinceEpoch(xValue.toInt());
                final dateStr = _formatTooltipDate(date, granularity);

                final currentSpot = spots.firstWhere((s) => s.barIndex == 0,
                    orElse: () =>
                        spots.first); // Assuming current is always index 0
                final previousSpot = showComparison
                    ? spots.firstWhere((s) => s.barIndex == 1,
                        orElse: () => currentSpot /* fallback */)
                    : null;

                List<TextSpan> children = [];
                // Add Current Value
                children.add(TextSpan(
                    text:
                        'Current: ${CurrencyFormatter.format(currentSpot.y, currencySymbol)}',
                    style: ChartUtils.tooltipContentStyle(context,
                        color: primaryColor)));

                // Add Previous Value if applicable
                if (showComparison &&
                    previousSpot != null &&
                    previousSpot.barIndex == 1) {
                  children.add(const TextSpan(text: '\n'));
                  children.add(TextSpan(
                      text:
                          'Previous: ${CurrencyFormatter.format(previousSpot.y, currencySymbol)}',
                      style: ChartUtils.tooltipContentStyle(context,
                          color: comparisonColor)));
                }

                return LineTooltipItem(
                  '$dateStr\n',
                  ChartUtils.tooltipTitleStyle(context),
                  children: children,
                  textAlign: TextAlign.left,
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          touchCallback:
              (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (onTapSpot != null &&
                event is FlTapUpEvent &&
                touchResponse != null &&
                touchResponse.lineBarSpots != null &&
                touchResponse.lineBarSpots!.isNotEmpty) {
              // Get index from the *current data* spot (barIndex 0)
              final currentSpot = touchResponse.lineBarSpots!.firstWhere(
                  (spot) => spot.barIndex == 0,
                  orElse: () => touchResponse.lineBarSpots![0]);
              final spotIndex = currentSpot.spotIndex;
              onTapSpot!(spotIndex);
            }
          },
        ),
      ),
    );
  }

  // Helper methods remain the same
  double? _calculateXInterval(
      double minX, double maxX, TimeSeriesGranularity granularity) {
    final durationMs = maxX - minX;
    if (durationMs <= 0) return null;
    // Aim for roughly 5-7 labels
    int divisions = 6;
    switch (granularity) {
      case TimeSeriesGranularity.daily:
        final days = durationMs / Duration.millisecondsPerDay;
        if (days <= divisions) return null; // Show all if few days
        return durationMs / divisions;
      case TimeSeriesGranularity.weekly:
        final weeks = durationMs / (Duration.millisecondsPerDay * 7);
        if (weeks <= divisions) return null;
        return durationMs / divisions;
      case TimeSeriesGranularity.monthly:
        final months = durationMs / (Duration.millisecondsPerDay * 30.44);
        if (months <= divisions) return null;
        return durationMs / divisions;
    }
    return null;
  }

  String _formatTooltipDate(DateTime date, TimeSeriesGranularity granularity) {
    switch (granularity) {
      case TimeSeriesGranularity.daily:
        return DateFormat('E, MMM d, yyyy')
            .format(date); // More specific for tooltip
      case TimeSeriesGranularity.weekly:
        final weekEnd = date.add(const Duration(days: 6));
        return 'Week: ${DateFormat.MMMd().format(date)} - ${DateFormat.MMMd().format(weekEnd)}';
      case TimeSeriesGranularity.monthly:
        return DateFormat('MMMM yyyy').format(date);
    }
  }

  Widget _bottomTitleWidgets(BuildContext context, double value, TitleMeta meta,
      TimeSeriesGranularity granularity) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(fontSize: 10);
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());

    // Determine the best date format based on the total range shown
    final firstDate = DateTime.fromMillisecondsSinceEpoch(meta.min.toInt());
    final lastDate = DateTime.fromMillisecondsSinceEpoch(meta.max.toInt());
    final durationDays = lastDate.difference(firstDate).inDays;

    String text;
    switch (granularity) {
      case TimeSeriesGranularity.daily:
        text = DateFormat('d').format(date);
        // Add month abbreviation if it's the first day or start of the range
        if (date.day == 1 || value == meta.min || durationDays < 10) {
          text = '${DateFormat('MMM').format(date)}\n$text';
        }
        break;
      case TimeSeriesGranularity.weekly:
        text = DateFormat('d').format(date); // Show start day of week
        // Add month if it's the first week shown or start of month
        if (date.day <= 7 || value == meta.min) {
          text = '${DateFormat('MMM').format(date)}\n$text';
        }
        break;
      case TimeSeriesGranularity.monthly:
        text = DateFormat('MMM').format(date);
        // Add year if it's January or the start of the range
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
