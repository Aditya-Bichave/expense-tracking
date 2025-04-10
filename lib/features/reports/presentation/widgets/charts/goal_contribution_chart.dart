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
      return const Center(child: Text("No contributions yet"));
    }

    final sortedContributions = List<GoalContribution>.from(contributions)
      ..sort((a, b) => a.date.compareTo(b.date));

    double cumulativeAmount = 0;
    final List<FlSpot> spots = sortedContributions.map((c) {
      cumulativeAmount += c.amount;
      return FlSpot(c.date.millisecondsSinceEpoch.toDouble(), cumulativeAmount);
    }).toList();

    if (spots.isEmpty) {
      return const Center(child: Text("No contribution data to chart"));
    }

    double minY = 0;
    double maxY = cumulativeAmount;
    double minX = spots.first.x;
    double maxX = spots.last.x;

    maxY = (maxY * 1.15).ceilToDouble();

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
            isCurved: false,
            color: primaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: spots.length < 20),
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
                final cumulativeAmount = barSpot.y;
                // Find original contribution (less efficient, might need optimization if slow)
                final originalContribution = sortedContributions.lastWhere(
                    (c) => c.date.millisecondsSinceEpoch <= barSpot.x.toInt(),
                    orElse: () => sortedContributions.first // Fallback
                    );

                return LineTooltipItem(
                  '${DateFormat.yMd().format(date)}\n',
                  ChartUtils.tooltipTitleStyle(context),
                  children: <TextSpan>[
                    TextSpan(
                      text:
                          'Contrib: ${CurrencyFormatter.format(originalContribution.amount, currencySymbol)}\n',
                      style: ChartUtils.tooltipContentStyle(context,
                          color:
                              primaryColor.withOpacity(0.8)), // Slightly dimmer
                    ),
                    TextSpan(
                      text:
                          'Total: ${CurrencyFormatter.format(cumulativeAmount, currencySymbol)}',
                      style: ChartUtils.tooltipContentStyle(context,
                          color: primaryColor),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  double? _calculateXInterval(double minX, double maxX, int dataLength) {
    final durationMs = maxX - minX;
    if (durationMs <= 0 || dataLength < 2) return null;
    return durationMs / 5; // Aim for ~5 labels
  }

  Widget _bottomTitleWidgets(
      BuildContext context, double value, TitleMeta meta) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(fontSize: 10);
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());

    final firstDate = DateTime.fromMillisecondsSinceEpoch(meta.min.toInt());
    final lastDate = DateTime.fromMillisecondsSinceEpoch(meta.max.toInt());
    final durationDays = lastDate.difference(firstDate).inDays;

    String text;
    if (durationDays > 365 * 1.5) {
      text = DateFormat('yyyy').format(date);
    } else if (durationDays > 60) {
      text = DateFormat('MMM yy').format(date);
    } else {
      text = DateFormat('M/d').format(date);
    }

    return SideTitleWidget(
        axisSide: meta.axisSide, space: 4, child: Text(text, style: style));
  }
}
