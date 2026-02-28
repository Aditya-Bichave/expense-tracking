import 'package:dartz/dartz.dart' hide State;
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/goal_contribution_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_gap.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_divider.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

class GoalProgressPage extends StatelessWidget {
  const GoalProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final settingsState = context.watch<SettingsBloc>().state;

    return BlocBuilder<GoalProgressReportBloc, GoalProgressReportState>(
      builder: (context, state) {
        final isComparisonEnabled = state is GoalProgressReportLoaded
            ? state.isComparisonEnabled
            : false;

        return ReportPageWrapper(
          title: 'Goal Progress',
          actions: [
            IconButton(
              icon: Icon(
                isComparisonEnabled
                    ? Icons.compare_arrows
                    : Icons.compare_arrows_outlined,
                color: isComparisonEnabled
                    ? kit.colors.primary
                    : kit.colors.textPrimary,
              ),
              tooltip: isComparisonEnabled ? "Hide Pacing" : "Show Pacing",
              onPressed: () {
                context.read<GoalProgressReportBloc>().add(
                  const ToggleComparison(),
                );
              },
            ),
          ],
          onExportCSV: () async {
            if (state is GoalProgressReportLoaded) {
              final helper = sl<CsvExportHelper>();
              final result = await helper.exportGoalProgressReport(
                state.reportData,
                settingsState.currencySymbol,
              );
              return result.fold(
                (csvString) => Right<Failure, String>(csvString),
                (failure) => Left<Failure, String>(failure),
              );
            }
            return Left<Failure, String>(
              const ExportFailure("Report not loaded. Cannot export."),
            );
          },
          body: Builder(
            builder: (context) {
              if (state is GoalProgressReportLoading) {
                return const Center(child: AppLoadingIndicator());
              }
              if (state is GoalProgressReportError) {
                return Center(
                  child: AppText(
                    "Error: ${state.message}",
                    color: kit.colors.error,
                  ),
                );
              }
              if (state is GoalProgressReportLoaded) {
                final reportData = state.reportData;
                if (reportData.progressData.isEmpty) {
                  return Center(
                    child: AppText(
                      "No active goals found.",
                      color: kit.colors.textSecondary,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reportData.progressData.length,
                  itemBuilder: (context, index) {
                    final goalData = reportData.progressData[index];
                    return _buildGoalProgressBridgeCard(
                      context,
                      goalData,
                      settingsState,
                      isComparisonEnabled,
                    );
                  },
                );
              }
              return const Center(
                child: AppText("Select filters to view report."),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGoalProgressBridgeCard(
    BuildContext context,
    GoalProgressData goalData,
    SettingsState settings,
    bool isComparisonEnabled,
  ) {
    final kit = context.kit;
    final currencySymbol = settings.currencySymbol;
    final goal = goalData.goal;
    final progressColor = goal.isAchieved
        ? Colors.green.shade600
        : kit.colors.primary;

    return AppCard(
      margin: kit.spacing.hMd.add(kit.spacing.vSm),
      elevation: 2,
      onTap: () => context.pushNamed(
        RouteNames.goalDetail,
        pathParameters: {'id': goal.id},
        extra: goal,
      ),
      child: Padding(
        padding: kit.spacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(goal.displayIconData, color: progressColor, size: 24),
                SizedBox(width: kit.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(goal.name, style: AppTextStyle.title),
                      if (goal.targetDate != null)
                        AppText(
                          'Target: ${DateFormatter.formatDate(goal.targetDate!)}',
                          style: AppTextStyle.caption,
                          color: kit.colors.textSecondary,
                        ),
                    ],
                  ),
                ),
                AppText(
                  '${(goal.percentageComplete * 100).toStringAsFixed(0)}%',
                  style: AppTextStyle.title,
                  color: progressColor,
                ),
              ],
            ),
            SizedBox(height: kit.spacing.sm),
            LinearPercentIndicator(
              padding: const BridgeEdgeInsets.only(),
              lineHeight: 10.0,
              percent: goal.percentageComplete.clamp(0.0, 1.0),
              barRadius: const Radius.circular(5),
              backgroundColor: kit.colors.surfaceContainer,
              progressColor: progressColor,
            ),
            SizedBox(height: kit.spacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  'Saved: ${CurrencyFormatter.format(goal.totalSaved, currencySymbol)}',
                  style: AppTextStyle.caption,
                  color: progressColor,
                ),
                AppText(
                  'Target: ${CurrencyFormatter.format(goal.targetAmount, currencySymbol)}',
                  style: AppTextStyle.caption,
                  color: kit.colors.textSecondary,
                ),
              ],
            ),
            if (isComparisonEnabled) ...[
              const AppDivider(),
              AppText(
                "Pacing Information",
                style: AppTextStyle.bodyStrong,
                color: kit.colors.primary,
              ),
              SizedBox(height: kit.spacing.xs),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildPacingItem(
                    context,
                    "Req. Daily",
                    goalData.requiredDailySaving,
                    currencySymbol,
                  ),
                  _buildPacingItem(
                    context,
                    "Req. Monthly",
                    goalData.requiredMonthlySaving,
                    currencySymbol,
                  ),
                  if (goalData.estimatedCompletionDate != null)
                    _buildPacingDateItem(
                      context,
                      "Est. Finish",
                      goalData.estimatedCompletionDate!,
                    ),
                ],
              ),
            ],
            if (goalData.contributions.isNotEmpty) ...[
              const AppDivider(),
              AppText("Recent Contributions", style: AppTextStyle.bodyStrong),
              SizedBox(height: kit.spacing.xs),
              SizedBox(
                height: 100,
                child: GoalContributionChart(
                  contributions: goalData.contributions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPacingItem(
    BuildContext context,
    String label,
    double? amount,
    String currencySymbol,
  ) {
    final kit = context.kit;
    String valueText = "N/A";
    if (amount != null && amount.isFinite) {
      valueText = CurrencyFormatter.format(amount, currencySymbol);
    } else if (amount != null && amount.isInfinite) {
      valueText = "Unreachable";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          style: AppTextStyle.caption,
          color: kit.colors.textSecondary,
        ),
        AppText(valueText, style: AppTextStyle.bodyStrong),
      ],
    );
  }

  Widget _buildPacingDateItem(
    BuildContext context,
    String label,
    DateTime date,
  ) {
    final kit = context.kit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          style: AppTextStyle.caption,
          color: kit.colors.textSecondary,
        ),
        AppText(DateFormatter.formatDate(date), style: AppTextStyle.bodyStrong),
      ],
    );
  }
}
