// lib/features/dashboard/presentation/widgets/budget_summary_widget.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
// import 'package:expense_tracker/features/budgets/domain/entities/budget.dart'; // Budget entity likely included in BudgetWithStatus
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart'; // Contains BudgetWithStatus
import 'package:expense_tracker/features/reports/presentation/widgets/charts/chart_utils.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart'; // For TimeSeriesDataPoint

class BudgetSummaryWidget extends StatelessWidget {
  final List<BudgetWithStatus> budgets; // Use correct type: BudgetWithStatus
  final List<TimeSeriesDataPoint>
      recentSpendingData; // Changed from recentContributionData

  const BudgetSummaryWidget({
    super.key,
    required this.budgets,
    required this.recentSpendingData,
  });

  // Helper to get sparkline data (similar to goal widget, adjust if needed)
  List<FlSpot> _getSparklineSpots(List<TimeSeriesDataPoint> data) {
    if (data.isEmpty) return [const FlSpot(0, 0)];
    double maxVal = 0;
    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final num currentVal = entry.value.currentAmount ?? 0;
      final double amount = currentVal.toDouble().clamp(0.0, double.maxFinite);
      if (amount > maxVal) maxVal = amount;
      return FlSpot(index, amount);
    }).toList();
    if (maxVal > 0) {
      return spots
          .map((spot) => FlSpot(spot.x, (spot.y / maxVal) * 10.0))
          .toList();
    } else {
      return spots.map((spot) => FlSpot(spot.x, 0)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    final sparklineSpots =
        _getSparklineSpots(recentSpendingData); // Use spending data

    if (budgets.isEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Budget Status'), // Changed title
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                        child: Column(children: [
                      Icon(
                          Icons.account_balance_wallet_outlined, // Changed icon
                          size: 32,
                          color: theme.colorScheme.secondary),
                      const SizedBox(height: 8),
                      Text("No active budgets found.", // Changed text
                          style: theme.textTheme.bodyMedium),
                      TextButton(
                          onPressed: () => context
                              .pushNamed(RouteNames.addBudget), // Changed route
                          child: const Text('Create Budget')) // Changed text
                    ]))))
          ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
            title: 'Budget Status (${budgets.length})'), // Changed title
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budgetWithStatus =
                budgets[index]; // Use correct type variable name
            // Use correct variable name and fields from BudgetWithStatus
            final budget = budgetWithStatus.budget;
            final progress = budgetWithStatus.percentageUsed.clamp(0.0, 1.0);
            final progressColor =
                budgetWithStatus.health == BudgetHealth.overLimit
                    ? Colors.red.shade600
                    : theme.colorScheme.primary;

            return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: InkWell(
                    onTap: () => context.pushNamed(
                        RouteNames.budgetDetail, // Changed route
                        pathParameters: {'id': budget.id},
                        extra: budget),
                    child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      // Assuming Budget has category and category has icon
                                      Icon(
                                          // Use a generic budget icon as category object isn't directly available
                                          Icons.account_balance_wallet_outlined,
                                          color: progressColor,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(
                                              budget.name, // Use budget name
                                              style: theme.textTheme.titleSmall,
                                              overflow: TextOverflow.ellipsis))
                                    ]),
                                    if (sparklineSpots.isNotEmpty &&
                                        sparklineSpots.length > 1)
                                      SizedBox(
                                          height: 20,
                                          width: 50,
                                          child: LineChart(
                                              ChartUtils.sparklineChartData(
                                                  sparklineSpots,
                                                  progressColor),
                                              duration: Duration.zero))
                                  ]),
                              const SizedBox(height: 8),
                              LinearPercentIndicator(
                                  padding: EdgeInsets.zero,
                                  lineHeight: 8.0,
                                  percent: progress, // Use budget progress
                                  barRadius: const Radius.circular(4),
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  progressColor: progressColor,
                                  animation: true,
                                  animationDuration: 600),
                              const SizedBox(height: 4),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        // Show spent vs limit
                                        'Spent: ${CurrencyFormatter.format(budgetWithStatus.amountSpent, currency)} / ${CurrencyFormatter.format(budget.targetAmount, currency)}', // Use targetAmount
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(color: progressColor)),
                                    Text(
                                        // Show percentage
                                        '${(progress * 100).toStringAsFixed(0)}%',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant))
                                  ])
                            ]))));
          },
        ),
        if (budgets.length >= 3) // Show 'View All' if 3 or more
          Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Center(
                  child: TextButton(
                      onPressed: () =>
                          context.go(RouteNames.budgetsAndCats, extra: {
                            'initialTabIndex': 0 // Navigate to Budgets tab
                          }),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                      child: const Text('View All Budgets')))) // Changed text
      ],
    );
  }
}
