import 'package:dartz/dartz.dart' hide State;
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/budget_performance_bar_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_divider.dart';
import 'package:expense_tracker/core/error/failure.dart';

class BudgetPerformancePage extends StatelessWidget {
  const BudgetPerformancePage({super.key});

  void _navigateToFilteredTransactions(
    BuildContext context,
    BudgetPerformanceData budgetItem,
  ) {
    final budget = budgetItem.budget;
    Map<String, String> filters = {};

    final filterBlocState = context.read<ReportFilterBloc>().state;

    filters['startDate'] = filterBlocState.startDate.toIso8601String();
    filters['endDate'] = filterBlocState.endDate.toIso8601String();

    if (budget.categoryIds != null && budget.categoryIds!.isNotEmpty) {
      filters['categoryId'] = budget.categoryIds!.join(',');
    }
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }

    log.info(
      "[BudgetPerformancePage] Navigating to transactions with filters: $filters",
    );
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final kit = context.kit;

    return ReportPageWrapper(
      title: AppLocalizations.of(context)!.budgetPerformance,
      actions: [
        BlocBuilder<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
          builder: (context, state) {
            final bool showComparison = state is BudgetPerformanceReportLoaded
                ? state.showComparison
                : false;
            final bool canCompare =
                state is BudgetPerformanceReportLoaded &&
                (state.reportData.previousPerformanceData != null ||
                    showComparison);

            return IconButton(
              icon: Icon(
                showComparison
                    ? Icons.compare_arrows_rounded
                    : Icons.compare_arrows_outlined,
                color: showComparison
                    ? kit.colors.primary
                    : kit.colors.textPrimary,
              ),
              tooltip: showComparison
                  ? AppLocalizations.of(context)!.hideComparison
                  : AppLocalizations.of(context)!.compareToPreviousPeriod,
              onPressed: canCompare
                  ? () => context.read<BudgetPerformanceReportBloc>().add(
                      const ToggleBudgetComparison(),
                    )
                  : null,
            );
          },
        ),
      ],
      onExportCSV: () async {
        final state = context.read<BudgetPerformanceReportBloc>().state;
        if (state is BudgetPerformanceReportLoaded) {
          final helper = sl<CsvExportHelper>();
          final result = await helper.exportBudgetPerformanceReport(
            state.reportData,
            currencySymbol,
            showComparison: state.showComparison,
          );
          return result.fold(
            (csvString) => Right<Failure, String>(csvString),
            (failure) => Left<Failure, String>(failure),
          );
        }
        return Left<Failure, String>(
          ExportFailure(AppLocalizations.of(context)!.reportDataNotLoadedYet),
        );
      },
      body:
          BlocBuilder<
            BudgetPerformanceReportBloc,
            BudgetPerformanceReportState
          >(
            builder: (context, state) {
              if (state is BudgetPerformanceReportLoading)
                return const Center(child: AppLoadingIndicator());
              if (state is BudgetPerformanceReportError)
                return Center(
                  child: AppText(
                    "Error: ${state.message}",
                    color: kit.colors.error,
                  ),
                );
              if (state is BudgetPerformanceReportLoaded) {
                final reportData = state.reportData;
                if (reportData.performanceData.isEmpty)
                  return Center(
                    child: AppText(
                      AppLocalizations.of(context)!.noBudgetsFoundForPeriod,
                      color: kit.colors.textSecondary,
                    ),
                  );
                final bool showComparison = state.showComparison;

                return ListView(
                  children: [
                    Padding(
                      padding: kit.spacing.vMd.add(kit.spacing.hSm),
                      child: SizedBox(
                        height: 250,
                        child: BudgetPerformanceBarChart(
                          data: reportData.performanceData,
                          previousData:
                              (showComparison &&
                                  reportData.previousPerformanceData != null)
                              ? reportData.previousPerformanceData
                              : null,
                          currencySymbol: currencySymbol,
                          onTapBar: (index) => _navigateToFilteredTransactions(
                            context,
                            reportData.performanceData[index],
                          ),
                        ),
                      ),
                    ),
                    const AppDivider(),
                    _buildDataTable(
                      context,
                      reportData,
                      settingsState,
                      showComparison,
                    ),
                    SizedBox(height: 80),
                  ],
                );
              }
              return const Center(
                child: AppText("Select filters to view report."),
              );
            },
          ),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    BudgetPerformanceReportData data,
    SettingsState settings,
    bool showComparison,
  ) {
    final kit = context.kit;
    final currencySymbol = settings.currencySymbol;

    List<DataColumn> columns = [
      DataColumn(label: AppText('Budget', style: AppTextStyle.bodyStrong)),
      DataColumn(
        label: AppText('Target', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
      DataColumn(
        label: AppText('Actual', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
      DataColumn(
        label: AppText('Variance', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
      DataColumn(
        label: AppText('Var %', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
    ];
    if (showComparison && data.previousPerformanceData != null) {
      columns.addAll([
        DataColumn(
          label: AppText('Prev Var %', style: AppTextStyle.bodyStrong),
          numeric: true,
        ),
        DataColumn(
          label: AppText('Var Δ%', style: AppTextStyle.bodyStrong),
          numeric: true,
        ),
      ]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 36,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 48,
        columns: columns,
        rows: data.performanceData.map((item) {
          final budget = item.budget;
          final varianceColor = item.currentVarianceAmount >= 0
              ? Colors.green.shade700
              : kit.colors.error;
          double? varianceChangePercent = item.varianceChangePercent;
          Color varianceChangeColor = kit.colors.textMuted;
          String varianceChangeText = "N/A";

          if (showComparison && varianceChangePercent != null) {
            if (varianceChangePercent.isInfinite) {
              varianceChangeText = varianceChangePercent.isNegative
                  ? '-∞'
                  : '+∞';
              varianceChangeColor = varianceChangePercent.isNegative
                  ? Colors.green.shade700
                  : kit.colors.error;
            } else if (!varianceChangePercent.isNaN) {
              varianceChangeText =
                  '${varianceChangePercent >= 0 ? '+' : ''}${varianceChangePercent.toStringAsFixed(0)}%';
              varianceChangeColor = varianceChangePercent <= 0
                  ? Colors.green.shade700
                  : kit.colors.error;
            }
          }

          return DataRow(
            cells: [
              DataCell(AppText(budget.name, overflow: TextOverflow.ellipsis)),
              DataCell(
                AppText(
                  CurrencyFormatter.format(budget.targetAmount, currencySymbol),
                ),
              ),
              DataCell(
                AppText(
                  CurrencyFormatter.format(
                    item.currentActualSpending,
                    currencySymbol,
                  ),
                ),
              ),
              DataCell(
                AppText(
                  CurrencyFormatter.format(
                    item.currentVarianceAmount,
                    currencySymbol,
                  ),
                  style: AppTextStyle.body,
                  color: varianceColor,
                ),
              ),
              DataCell(
                AppText(
                  item.currentVariancePercent.isFinite
                      ? '${item.currentVariancePercent.toStringAsFixed(1)}%'
                      : (item.currentVariancePercent.isNegative ? '-∞' : '+∞'),
                  style: AppTextStyle.body,
                  color: varianceColor,
                ),
              ),
              if (showComparison && data.previousPerformanceData != null)
                DataCell(
                  AppText(
                    item.previousVariancePercent?.isFinite == true
                        ? '${item.previousVariancePercent!.toStringAsFixed(1)}%'
                        : 'N/A',
                  ),
                ),
              if (showComparison && data.previousPerformanceData != null)
                DataCell(
                  AppText(
                    varianceChangeText,
                    style: AppTextStyle.body,
                    color: varianceChangeColor,
                  ),
                ),
            ],
            onSelectChanged: (selected) {
              if (selected == true) {
                _navigateToFilteredTransactions(context, item);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
