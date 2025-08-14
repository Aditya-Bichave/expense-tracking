import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart'; // For TimeSeriesDataPoint

class BudgetSummaryWidget extends StatelessWidget {
  final List<BudgetWithStatus> budgets;
  final List<TimeSeriesDataPoint> recentSpendingData;

  const BudgetSummaryWidget({
    super.key,
    required this.budgets,
    required this.recentSpendingData,
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
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    final sparklineSpots = _getSparklineSpots(recentSpendingData);

    if (budgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Budget Status'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 32,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No active budgets found.",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () =>
                            context.pushNamed(RouteNames.addBudget),
                        child: const Text('Create Budget'),
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
        SectionHeader(title: 'Budget Status (${budgets.length})'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budgetWithStatus = budgets[index];
            final budget = budgetWithStatus.budget;
            final progress = budgetWithStatus.percentageUsed.clamp(0.0, 1.0);
            final progressColor =
                budgetWithStatus.health == BudgetHealth.overLimit
                ? theme
                      .colorScheme
                      .error // Use theme error color
                : theme.colorScheme.primary;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                onTap: () => context.pushNamed(
                  RouteNames.budgetDetail,
                  pathParameters: {'id': budget.id},
                  extra: budget,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Wrap the inner Row with Flexible to constrain width
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min, // Important
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: progressColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                // Use Flexible instead of Expanded inside Row
                                Flexible(
                                  child: Text(
                                    budget.name,
                                    style: theme.textTheme.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Keep SizedBox for sparkline if it exists
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
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 8.0,
                        percent: progress,
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
                            'Spent: ${CurrencyFormatter.format(budgetWithStatus.amountSpent, currency)} / ${CurrencyFormatter.format(budget.targetAmount, currency)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: progressColor,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (budgets.length >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Center(
              child: TextButton(
                onPressed: () => context.go(
                  RouteNames.budgetsAndCats,
                  extra: {
                    'initialTabIndex': 0, // Navigate to Budgets tab
                  },
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('View All Budgets'),
              ),
            ),
          ),
      ],
    );
  }
}
