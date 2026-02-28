// lib/features/dashboard/presentation/widgets/goal_summary_widget.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_text.dart';
import 'package:expense_tracker/ui_bridge/bridge_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

class GoalSummaryWidget extends StatelessWidget {
  final List<Goal> goals;
  final List<TimeSeriesDataPoint> recentContributionData;

  const GoalSummaryWidget({
    super.key,
    required this.goals,
    required this.recentContributionData,
  });

  List<FlSpot> _getSparklineSpots(List<TimeSeriesDataPoint> data) {
    if (data.isEmpty) return [const FlSpot(0, 0)];
    return data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final num currentVal = entry.value.currentAmount;
      final double amount = currentVal.toDouble().clamp(0.0, double.maxFinite);
      return FlSpot(index, amount);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    final sparklineSpots = _getSparklineSpots(recentContributionData);

    if (goals.isEmpty) {
      return Padding(
        padding: kit.spacing.vSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Goal Progress'),
            AppCard(
              padding: kit.spacing.allLg,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 32,
                      color: kit.colors.textSecondary,
                    ),
                    kit.spacing.gapSm,
                    BridgeText(
                      "No savings goals set yet.",
                      style: kit.typography.body,
                    ),
                    BridgeButton.ghost(
                      key: const ValueKey('button_goalSummary_create'),
                      onPressed: () => context.pushNamed(RouteNames.addGoal),
                      label: 'Create Goal',
                    ),
                  ],
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
        Column(
          children: goals.map((goal) {
            final progress = goal.percentageComplete;
            final progressColor = goal.isAchieved
                ? kit.colors.success
                : kit.colors.primary;
            return AppCard(
              margin: kit.spacing.vXs,
              onTap: () => context.pushNamed(
                RouteNames.goalDetail,
                pathParameters: {'id': goal.id},
                extra: goal,
              ),
              padding: kit.spacing.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap the inner Row with Flexible
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Important
                          children: [
                            Icon(
                              goal.displayIconData,
                              color: progressColor,
                              size: 20,
                            ),
                            kit.spacing.gapSm,
                            // Use Flexible instead of Expanded
                            Flexible(
                              child: BridgeText(
                                goal.name,
                                style: kit.typography.title.copyWith(
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (sparklineSpots.isNotEmpty &&
                          sparklineSpots.length > 1)
                        SizedBox(
                          height: 20,
                          width: 50, // Ensure sparkline has width
                          child: LineChart(
                            ChartUtils.sparklineChartData(
                              sparklineSpots,
                              progressColor,
                            ),
                            duration: Duration.zero,
                          ),
                        ),
                    ],
                  ),
                  kit.spacing.gapSm,
                  LinearPercentIndicator(
                    padding: const EdgeInsets.only(),
                    lineHeight: 8.0,
                    percent: progress.clamp(0.0, 1.0),
                    barRadius: const Radius.circular(4),
                    backgroundColor: kit.colors.surfaceContainer,
                    progressColor: progressColor,
                    animation: true,
                    animationDuration: 600,
                  ),
                  kit.spacing.gapXs,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BridgeText(
                        'Saved: ${CurrencyFormatter.format(goal.totalSaved, currency)}',
                        style: kit.typography.caption.copyWith(
                          color: progressColor,
                        ),
                      ),
                      BridgeText(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: kit.typography.caption.copyWith(
                          color: kit.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (goals.length >= 3)
          Padding(
            padding: EdgeInsets.only(top: kit.spacing.xs),
            child: Center(
              child: BridgeButton.ghost(
                key: const ValueKey('button_goalSummary_viewAll'),
                onPressed: () => context.go(
                  RouteNames.budgetsAndCats,
                  extra: {
                    'initialTabIndex': 1, // Navigate to Goals tab
                  },
                ),
                label: 'View All Goals',
              ),
            ),
          ),
      ],
    );
  }
}
