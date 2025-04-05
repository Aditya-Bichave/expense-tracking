// lib/features/dashboard/presentation/widgets/goal_summary_widget.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/router.dart'; // Import AppRouter for route names

class GoalSummaryWidget extends StatelessWidget {
  final List<Goal> goals;

  const GoalSummaryWidget({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;

    if (goals.isEmpty) {
      return const SizedBox.shrink();
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
            final progressColor =
                goal.isAchieved ? Colors.green : theme.colorScheme.primary;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                onTap: () {
                  context.pushNamed(RouteNames.goalDetail,
                      pathParameters: {'id': goal.id}, extra: goal);
                  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Navigate to goal detail ${goal.id}")));
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    // Use Row for better layout
                    children: [
                      Icon(goal.displayIconData,
                          color: progressColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.name,
                                style: theme.textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            LinearPercentIndicator(
                              padding: EdgeInsets.zero,
                              lineHeight: 8.0,
                              percent: progress.clamp(0.0, 1.0),
                              barRadius: const Radius.circular(4),
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              progressColor: progressColor,
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
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Optional "View All" button
        if (goals.length >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Center(
              child: TextButton(
                child: const Text('View All Goals'),
                onPressed: () => context.go(RouteNames.budgetsAndCats,
                    extra: {'initialTabIndex': 2}), // Navigate to goals tab
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
          ),
      ],
    );
  }
}
