// lib/features/dashboard/presentation/widgets/goal_summary_widget.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart'; // Import ChartUtils
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart'; // For TimeSeriesDataPoint (if needed later)

class GoalSummaryWidget extends StatelessWidget {
  final List<Goal> goals;
  // --- ADDED: Accept Sparkline Data (Optional, could fetch specific contribution history) ---
  // For simplicity, we'll reuse the recent spending sparkline for now,
  // but ideally, this would show contribution trends.
  final List<TimeSeriesDataPoint> recentContributionDataPlaceholder;

  const GoalSummaryWidget({
    super.key,
    required this.goals,
    required this.recentContributionDataPlaceholder, // Require placeholder
  });
  // --- END ADD ---

  List<FlSpot> _getSparklineSpots(List<TimeSeriesDataPoint> data) {
    if (data.isEmpty) return [const FlSpot(0, 5)]; // Default placeholder
    return data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final amount = entry.value.amount;
      return FlSpot(index, amount.clamp(0, double.maxFinite));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    // --- Get sparkline spots ---
    final sparklineSpots =
        _getSparklineSpots(recentContributionDataPlaceholder);

    if (goals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Goal Progress'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.savings_outlined,
                          size: 32, color: theme.colorScheme.secondary),
                      const SizedBox(height: 8),
                      Text("No savings goals set yet.",
                          style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.pushNamed(RouteNames.addGoal),
                        child: const Text('Create Goal'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Goal Progress (${goals.length})'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            final progress = goal.percentageComplete;
            final progressColor = goal.isAchieved
                ? Colors.green.shade600
                : theme.colorScheme.primary;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                onTap: () => context.pushNamed(RouteNames.goalDetail,
                    pathParameters: {'id': goal.id}, extra: goal),
                child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              // Icon and Name
                              children: [
                                Icon(goal.displayIconData,
                                    color: progressColor, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(goal.name,
                                        style: theme.textTheme.titleSmall,
                                        overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            SizedBox(
                              // Sparkline
                              height: 20,
                              width: 50,
                              child: LineChart(
                                ChartUtils.sparklineChartData(sparklineSpots,
                                    progressColor), // Use placeholder/recent
                                duration: Duration.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearPercentIndicator(
                          padding: EdgeInsets.zero,
                          lineHeight: 8.0,
                          percent: progress.clamp(0.0, 1.0),
                          barRadius: const Radius.circular(4),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          progressColor: progressColor,
                          animation: true,
                          animationDuration: 600,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saved: ${CurrencyFormatter.format(goal.totalSaved, currency)}',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: progressColor),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    )),
              ),
            );
          },
        ),
        if (goals.length >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Center(
              child: TextButton(
                onPressed: () => context.go(RouteNames.budgetsAndCats, extra: {
                  'initialTabIndex': 1
                }), // Corrected index for Goals tab
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('View All Goals'),
              ),
            ),
          ),
      ],
    );
  }
}

// Removed duplicate ChartUtils class
