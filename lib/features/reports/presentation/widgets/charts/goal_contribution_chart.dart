// lib/features/reports/presentation/widgets/charts/goal_contribution_chart.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class GoalContributionChart extends StatelessWidget {
  final List<GoalContribution> contributions;

  const GoalContributionChart({super.key, required this.contributions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final primaryColor = theme.colorScheme.primary;

    if (contributions.isEmpty) {
      return const Center(child: Text("No contributions to chart"));
    }

    // Sort for cumulative calculation
    final sortedContributions = List<GoalContribution>.from(contributions)
      ..sort((a, b) => a.date.compareTo(b.date));

    double cumulativeAmount = 0;
    final List<FlSpot> spots = sortedContributions.map((c) {
      cumulativeAmount += c.amount;
      // Use milliseconds since epoch for x-axis to handle dates correctly
      return FlSpot(c.date.millisecondsSinceEpoch.toDouble(), cumulativeAmount);
    }).toList();

    if (spots.isEmpty) {
      return const Center(child: Text("No contribution data to chart"));
    }

    double minY = 0;
    double maxY = cumulativeAmount; // Max Y is the final cumulative amount
    double minX = spots.first.x;
    double maxX = spots.last.x;

    // Add some padding to the Y-axis
    maxY = (maxY * 1.15).ceilToDouble();
    if (maxY <= 0) maxY = 10; // Ensure maxY is at least 10 if total is 0

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5, // Aim for 5 horizontal lines
          verticalInterval: _calculateXInterval(minX, maxX,
              sortedContributions.length), // Calculate interval dynamically
          getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.1), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(
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
              interval:
                  _calculateXInterval(minX, maxX, sortedContributions.length),
              getTitlesWidget: (value, meta) =>
                  _bottomTitleWidgets(context, value, meta),
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
            isCurved: true, // Smoother curve
            gradient: LinearGradient(
              // Add gradient
              colors: [primaryColor.withOpacity(0.8), primaryColor],
            ),
            barWidth: 3, // Slightly thicker line
            isStrokeCapRound: true,
            dotData: FlDotData(
                show: spots.length < 20), // Show dots for fewer points
            belowBarData: BarAreaData(
              // Enhanced area below
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
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final date =
                    DateTime.fromMillisecondsSinceEpoch(barSpot.x.toInt());
                final cumulativeAmount = barSpot.y;
                // Find original contribution (less efficient, okay for tooltips)
                final originalContribution = sortedContributions.lastWhere(
                    (c) => c.date.millisecondsSinceEpoch <= barSpot.x.toInt(),
                    orElse: () => sortedContributions.first // Fallback
                    );

                return LineTooltipItem(
                  '${DateFormat.yMd().format(date)}\n', // Date format
                  ChartUtils.tooltipTitleStyle(context),
                  children: <TextSpan>[
                    TextSpan(
                      text:
                          'Contrib: ${CurrencyFormatter.format(originalContribution.amount, currencySymbol)}',
                      style: ChartUtils.tooltipContentStyle(context,
                          color: primaryColor.withOpacity(0.8)),
                    ),
                    const TextSpan(text: '\n'), // New line
                    TextSpan(
                      text:
                          'Total: ${CurrencyFormatter.format(cumulativeAmount, currencySymbol)}',
                      style: ChartUtils.tooltipContentStyle(context,
                          color: primaryColor),
                    ),
                  ],
                  textAlign: TextAlign.left, // Align text left
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          // --- ADDED: Touch callback ---
          touchCallback:
              (FlTouchEvent event, LineTouchResponse? touchResponse) {
            // Example: Log tap - Add actual drill-down logic if needed
            if (event is FlTapUpEvent &&
                touchResponse != null &&
                touchResponse.lineBarSpots != null &&
                touchResponse.lineBarSpots!.isNotEmpty) {
              final spotIndex = touchResponse.lineBarSpots![0].spotIndex;
              if (spotIndex < sortedContributions.length) {
                // Potential drill-down:
                // final tappedContribution = sortedContributions[spotIndex];
                // showLogContributionSheet(context, tappedContribution.goalId, initialContribution: tappedContribution);
              }
            }
          },
          // --- END ADDED ---
        ),
      ),
    );
  }

  // --- Helper methods unchanged ---
  double? _calculateXInterval(double minX, double maxX, int dataLength) {
    final durationMs = maxX - minX;
    if (durationMs <= 0 || dataLength < 2) {
      return null; // Avoid division by zero or single point
    }
    // Aim for about 5 labels on the x-axis
    final double interval = durationMs / 5;
    // Ensure interval is at least one day if duration is short
    return interval > Duration.millisecondsPerDay ? interval : null;
  }

  Widget _bottomTitleWidgets(
      BuildContext context, double value, TitleMeta meta) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(fontSize: 10);
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());

    // Determine the best date format based on the total range shown
    final firstDate = DateTime.fromMillisecondsSinceEpoch(meta.min.toInt());
    final lastDate = DateTime.fromMillisecondsSinceEpoch(meta.max.toInt());
    final durationDays = lastDate.difference(firstDate).inDays;

    String text;
    if (durationDays > 365 * 1.5) {
      // More than 1.5 years -> Show Year
      text = DateFormat('yyyy').format(date);
    } else if (durationDays > 60) {
      // More than 2 months -> Show Month/Year
      text = DateFormat('MMM yy').format(date);
    } else {
      // Less than 2 months -> Show Month/Day
      text = DateFormat('M/d').format(date);
    }

    // Avoid label overlap by checking distance to min/max (simplistic check)
    // TODO: implement smarter label hiding if needed
    return SideTitleWidget(
        axisSide: meta.axisSide, space: 4, child: Text(text, style: style));
  }
}
