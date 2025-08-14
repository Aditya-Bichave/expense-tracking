// lib/features/reports/presentation/pages/goal_progress_page.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/contribution_list_item.dart'; // Reuse contribution item
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/goal_contribution_chart.dart'; // Specific chart
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart'; // Or Circular

class GoalProgressPage extends StatelessWidget {
  const GoalProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;

    return ReportPageWrapper(
      title: 'Goal Progress',
      // TODO: Add actions like filter by goal, comparison toggle, export
      body: BlocBuilder<GoalProgressReportBloc, GoalProgressReportState>(
        builder: (context, state) {
          if (state is GoalProgressReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GoalProgressReportError) {
            return Center(
                child: Text("Error: ${state.message}",
                    style: TextStyle(color: theme.colorScheme.error)));
          }
          if (state is GoalProgressReportLoaded) {
            final reportData = state.reportData;
            if (reportData.progressData.isEmpty) {
              return const Center(child: Text("No active goals found."));
            }

            return ListView.builder(
              itemCount: reportData.progressData.length,
              itemBuilder: (context, index) {
                final goalData = reportData.progressData[index];
                return _buildGoalProgressCard(context, goalData, settingsState);
              },
            );
          }
          return const Center(child: Text("Select filters to view report."));
        },
      ),
    );
  }

  Widget _buildGoalProgressCard(
      BuildContext context, GoalProgressData goalData, SettingsState settings) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;
    final goal = goalData.goal;
    final progressColor =
        goal.isAchieved ? Colors.green.shade600 : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => context.pushNamed(RouteNames.goalDetail,
            pathParameters: {'id': goal.id}, extra: goal),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(goal.displayIconData, color: progressColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.name, style: theme.textTheme.titleMedium),
                        if (goal.targetDate != null)
                          Text(
                              'Target: ${DateFormatter.formatDate(goal.targetDate!)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text('${(goal.percentageComplete * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: progressColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              LinearPercentIndicator(
                padding: EdgeInsets.zero,
                lineHeight: 10.0,
                percent: goal.percentageComplete.clamp(0.0, 1.0),
                barRadius: const Radius.circular(5),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                progressColor: progressColor,
              ),
              const SizedBox(height: 6),
              // Amounts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      'Saved: ${CurrencyFormatter.format(goal.totalSaved, currencySymbol)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: progressColor)),
                  Text(
                      'Target: ${CurrencyFormatter.format(goal.targetAmount, currencySymbol)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              // Contribution Chart (Optional)
              if (goalData.contributions.isNotEmpty) ...[
                const Divider(height: 24),
                Text("Recent Contributions", style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100, // Adjust height as needed
                  child: GoalContributionChart(
                      contributions: goalData.contributions),
                ),
                // Or show list:
                // _buildContributionList(context, goalData.contributions, settings)
              ]
            ],
          ),
        ),
      ),
    );
  }

  // Optional: Helper to build a short list of recent contributions
}
