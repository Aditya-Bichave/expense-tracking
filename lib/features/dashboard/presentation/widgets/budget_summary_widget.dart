// lib/features/dashboard/presentation/widgets/budget_summary_widget.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart'; // Import ChartUtils
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart'; // For TimeSeriesDataPoint

class BudgetSummaryWidget extends StatelessWidget {
  final List<BudgetWithStatus> budgets;
  // --- ADDED: Accept Sparkline Data ---
  final List<TimeSeriesDataPoint> recentSpendingData;

  const BudgetSummaryWidget({
    super.key,
    required this.budgets,
    required this.recentSpendingData, // Require sparkline data
  });
  // --- END ADD ---

  // Convert TimeSeriesDataPoint to FlSpot for the chart
  List<FlSpot> _getSparklineSpots(List<TimeSeriesDataPoint> data) {
    if (data.isEmpty) return [const FlSpot(0, 5)]; // Default placeholder
    // Normalize X values to be 0, 1, 2... for the sparkline display
    return data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final amount = entry.value.amount;
      return FlSpot(
          index, amount.clamp(0, double.maxFinite)); // Ensure non-negative
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;

    // --- Get sparkline spots ---
    final sparklineSpots = _getSparklineSpots(recentSpendingData);
    // --- End Get ---

    if (budgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Budget Watch'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.pie_chart_outline,
                          size: 32, color: theme.colorScheme.secondary),
                      const SizedBox(height: 8),
                      Text("No budgets created yet.",
                          style: theme.textTheme.bodyMedium),
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
        SectionHeader(title: 'Budget Watch (${budgets.length})'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final status = budgets[index];
            final budget = status.budget;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                onTap: () => context.pushNamed(RouteNames.budgetDetail,
                    pathParameters: {'id': budget.id}),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(budget.name,
                                  style: theme.textTheme.titleSmall,
                                  overflow: TextOverflow.ellipsis)),
                          SizedBox(
                            height: 20,
                            width: 50,
                            child: LineChart(
                              ChartUtils.sparklineChartData(sparklineSpots,
                                  status.statusColor), // Use prepared spots
                              duration: Duration.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 8.0,
                        percent: status.percentageUsed.clamp(0.0, 1.0),
                        barRadius: const Radius.circular(4),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        progressColor: status.statusColor,
                        animation: true,
                        animationDuration: 600,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Spent: ${CurrencyFormatter.format(status.amountSpent, currency)}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: status.statusColor),
                          ),
                          Text(
                            status.amountRemaining >= 0
                                ? '${CurrencyFormatter.format(status.amountRemaining, currency)} left'
                                : '${CurrencyFormatter.format(status.amountRemaining.abs(), currency)} over',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
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
                onPressed: () => context.go(RouteNames.budgetsAndCats),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('View All Budgets'),
              ),
            ),
          ),
      ],
    );
  }
}

// Removed duplicate ChartUtils class
