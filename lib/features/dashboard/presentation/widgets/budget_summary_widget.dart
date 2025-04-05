// lib/features/dashboard/presentation/widgets/budget_summary_widget.dart
import 'package:expense_tracker/core/constants/route_names.dart'; // <<< ENSURE THIS IMPORT EXISTS
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';

class BudgetSummaryWidget extends StatelessWidget {
  final List<BudgetWithStatus> budgets;

  const BudgetSummaryWidget({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;

    if (budgets.isEmpty) {
      return const SizedBox.shrink();
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
                onTap: () {
                  // Use the correct RouteName constant
                  context.pushNamed(
                      RouteNames.budgetDetail, // <<< CORRECTED RouteName usage
                      pathParameters: {'id': budget.id}
                      // Pass budgetStatus via extra if detail page needs it immediately
                      // extra: status,
                      );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.name,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 8.0,
                        percent: status.percentageUsed.clamp(0.0, 1.0),
                        barRadius: const Radius.circular(4),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        progressColor: status.statusColor,
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
                child: const Text('View All Budgets'),
                onPressed: () => context.go(RouteNames.budgetsAndCats),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
          ),
      ],
    );
  }
}
