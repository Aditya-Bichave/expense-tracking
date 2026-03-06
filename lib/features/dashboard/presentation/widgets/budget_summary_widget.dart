// lib/features/dashboard/presentation/widgets/budget_summary_widget.dart
import 'package:flutter/foundation.dart'; // Import for kIsWeb
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
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_text.dart';
import 'package:expense_tracker/ui_bridge/bridge_button.dart';

class BudgetSummaryWidget extends StatelessWidget {
  final List<BudgetWithStatus> budgets;
  final List<TimeSeriesDataPoint> recentSpendingData;
  final bool disableAnimations;

  const BudgetSummaryWidget({
    super.key,
    required this.budgets,
    required this.recentSpendingData,
    this.disableAnimations = false,
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
    final sparklineSpots = _getSparklineSpots(recentSpendingData);

    // Use injected flag, or fallback to environment check if not provided,
    // but prefer standard kIsWeb or test binding in real apps.
    // Here we support disableAnimations param for testability.
    // Also checking if environment contains FLUTTER_TEST is removed to support web.
    // We can rely on disableAnimations being passed in tests if needed, or just let animations run (pumpAndSettle handles them).
    final shouldAnimate = !disableAnimations;

    if (budgets.isEmpty) {
      return Padding(
        padding: kit.spacing.vSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Budget Status'),
            AppCard(
              padding: kit.spacing.allLg,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 32,
                      color: kit.colors.textSecondary,
                    ),
                    kit.spacing.gapSm,
                    BridgeText(
                      "No active budgets found.",
                      style: kit.typography.body,
                    ),
                    BridgeButton.ghost(
                      key: const ValueKey('button_budgetSummary_create'),
                      onPressed: () => context.pushNamed(RouteNames.addBudget),
                      label: 'Create Budget',
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
        SectionHeader(title: 'Budget Status (${budgets.length})'),
        Column(
          children: budgets.map((budgetWithStatus) {
            final budget = budgetWithStatus.budget;
            final progress = budgetWithStatus.percentageUsed.clamp(0.0, 1.0);
            final progressColor =
                budgetWithStatus.health == BudgetHealth.overLimit
                ? kit
                      .colors
                      .error // Use theme error color
                : kit.colors.primary;

            return AppCard(
              margin: kit.spacing.vXs,
              onTap: () => context.pushNamed(
                RouteNames.budgetDetail,
                pathParameters: {'id': budget.id},
                extra: budget,
              ),
              padding: kit.spacing.allMd,
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
                            kit.spacing.gapSm,
                            // Use Flexible instead of Expanded inside Row
                            Flexible(
                              child: BridgeText(
                                budget.name,
                                style: kit.typography.title.copyWith(
                                  fontSize: 16,
                                ),
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
                  kit.spacing.gapSm,
                  LinearPercentIndicator(
                    padding: const EdgeInsets.only(),
                    lineHeight: 8.0,
                    percent: progress,
                    barRadius: const Radius.circular(4),
                    backgroundColor: kit.colors.surfaceContainer,
                    progressColor: progressColor,
                    animation: shouldAnimate,
                    animationDuration: 600,
                  ),
                  kit.spacing.gapXs,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BridgeText(
                        'Spent: ${CurrencyFormatter.format(budgetWithStatus.amountSpent, currency)} / ${CurrencyFormatter.format(budget.targetAmount, currency)}',
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
        if (budgets.length >= 3)
          Padding(
            padding: EdgeInsets.only(top: kit.spacing.xs),
            child: Center(
              child: BridgeButton.ghost(
                key: const ValueKey('button_budgetSummary_viewAll'),
                onPressed: () => context.go(
                  RouteNames.budgetsAndCats,
                  extra: {
                    'initialTabIndex': 0, // Navigate to Budgets tab
                  },
                ),
                label: 'View All Budgets',
              ),
            ),
          ),
      ],
    );
  }
}
