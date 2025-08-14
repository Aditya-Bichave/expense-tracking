// lib/features/reports/presentation/pages/budget_performance_page.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart'; // For ExportFailure
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/budget_performance_bar_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';

class BudgetPerformancePage extends StatelessWidget {
  const BudgetPerformancePage({super.key});

  void _navigateToFilteredTransactions(BuildContext context, Budget budget) {
    // ... (implementation unchanged) ...
    final filterBlocState = context.read<ReportFilterBloc>().state;
    // Use budget period if one-time, else use report filter dates
    final (start, end) = budget.period == BudgetPeriodType.oneTime &&
            budget.startDate != null &&
            budget.endDate != null
        ? (budget.startDate!, budget.endDate!)
        : (filterBlocState.startDate, filterBlocState.endDate);

    // Ensure end date includes full day
    final endDateEndOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final Map<String, String> filters = {
      'startDate': start.toIso8601String(),
      'endDate': endDateEndOfDay.toIso8601String(),
      'type': TransactionType.expense.name,
    };
    if (budget.type == BudgetType.categorySpecific &&
        budget.categoryIds != null &&
        budget.categoryIds!.isNotEmpty) {
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
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    return ReportPageWrapper(
      title: AppLocalizations.of(context)!.budgetPerformance,
      actions: [
        BlocBuilder<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
          builder: (context, state) {
            final bool showComparison = state is BudgetPerformanceReportLoaded
                ? state.showComparison
                : false;
            // Enable comparison button only if loaded state has previous data OR if currently showing comparison (to allow hiding)
            final bool canCompare = state is BudgetPerformanceReportLoaded &&
                (state.reportData.previousPerformanceData != null ||
                    showComparison);

            return IconButton(
              icon: Icon(
                showComparison
                    ? Icons.compare_arrows_rounded
                    : Icons.compare_arrows_outlined,
              ),
              tooltip: showComparison
                  ? AppLocalizations.of(context)!.hideComparison
                  : AppLocalizations.of(context)!.compareToPreviousPeriod,
              color: showComparison ? theme.colorScheme.primary : null,
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
          return helper.exportBudgetPerformanceReport(
            state.reportData,
            currencySymbol,
            showComparison: state.showComparison,
          ); // Pass flag
        }
        return Right(
          ExportFailure(AppLocalizations.of(context)!.reportDataNotLoadedYet),
        );
      },
      body: BlocBuilder<BudgetPerformanceReportBloc,
          BudgetPerformanceReportState>(
        builder: (context, state) {
          if (state is BudgetPerformanceReportLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is BudgetPerformanceReportError)
            return Center(
              child: Text(
                "Error: ${state.message}",
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          if (state is BudgetPerformanceReportLoaded) {
            final reportData = state.reportData;
            if (reportData.performanceData.isEmpty)
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.noBudgetsFoundForPeriod,
                ),
              );
            final bool showComparison = state.showComparison; // Use state flag

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 8.0,
                  ),
                  child: SizedBox(
                    height: 250,
                    child: BudgetPerformanceBarChart(
                      data: reportData.performanceData,
                      // Pass previous data if available and comparison is enabled
                      previousData: (showComparison &&
                              reportData.previousPerformanceData != null)
                          ? reportData.previousPerformanceData
                          : null,
                      currencySymbol: currencySymbol,
                      onTapBar: (index) => _navigateToFilteredTransactions(
                        context,
                        reportData.performanceData[index].budget,
                      ), // Add tap handler
                    ),
                  ),
                ),
                const Divider(),
                _buildDataTable(
                  context,
                  reportData,
                  settingsState,
                  showComparison,
                ), // Pass comparison flag
                const SizedBox(height: 80),
              ],
            );
          }
          return const Center(child: Text("Select filters to view report."));
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
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;

    List<DataColumn> columns = [
      const DataColumn(label: Text('Budget')),
      const DataColumn(label: Text('Target'), numeric: true),
      const DataColumn(label: Text('Actual'), numeric: true),
      const DataColumn(label: Text('Variance'), numeric: true),
      const DataColumn(
        label: Text('Var %'),
        numeric: true,
      ), // Current Variance %
    ];
    // Add comparison columns dynamically only if showComparison is true AND previous data exists
    if (showComparison && data.previousPerformanceData != null) {
      columns.addAll([
        const DataColumn(label: Text('Prev Var %'), numeric: true),
        const DataColumn(
          label: Text('Var Δ%'),
          numeric: true,
        ), // Variance Change %
      ]);
    }

    final Map<String, BudgetPerformanceData> previousDataMap =
        (showComparison && data.previousPerformanceData != null)
            ? {
                for (var item in data.previousPerformanceData!)
                  item.budget.id: item
              }
            : {};

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
              : theme.colorScheme.error;
          double? varianceChangePercent =
              item.varianceChangePercent; // Use getter from entity
          Color varianceChangeColor = theme.disabledColor;
          String varianceChangeText = "N/A";

          if (showComparison && varianceChangePercent != null) {
            if (varianceChangePercent.isInfinite) {
              varianceChangeText =
                  varianceChangePercent.isNegative ? '-∞' : '+∞';
              // Improvement is negative change (less overspending or more underspending)
              varianceChangeColor = varianceChangePercent.isNegative
                  ? Colors.green.shade700
                  : theme.colorScheme.error;
            } else if (!varianceChangePercent.isNaN) {
              varianceChangeText =
                  '${varianceChangePercent >= 0 ? '+' : ''}${varianceChangePercent.toStringAsFixed(0)}%';
              varianceChangeColor = varianceChangePercent <= 0
                  ? Colors.green.shade700
                  : theme.colorScheme.error; // Negative/zero change is good
            }
          }

          return DataRow(
            cells: [
              DataCell(Text(budget.name, overflow: TextOverflow.ellipsis)),
              DataCell(
                Text(
                  CurrencyFormatter.format(budget.targetAmount, currencySymbol),
                ),
              ),
              DataCell(
                Text(
                  CurrencyFormatter.format(
                    item.currentActualSpending,
                    currencySymbol,
                  ),
                ),
              ), // Use getter
              DataCell(
                Text(
                  CurrencyFormatter.format(
                    item.currentVarianceAmount,
                    currencySymbol,
                  ), // Use getter
                  style: TextStyle(color: varianceColor),
                ),
              ),
              DataCell(
                Text(
                  item.currentVariancePercent.isFinite
                      ? '${item.currentVariancePercent.toStringAsFixed(1)}%'
                      : (item.currentVariancePercent.isNegative ? '-∞' : '+∞'),
                  style: TextStyle(color: varianceColor),
                ),
              ),
              // Conditionally add comparison cells
              if (showComparison && data.previousPerformanceData != null)
                DataCell(
                  Text(
                    item.previousVariancePercent?.isFinite == true
                        ? '${item.previousVariancePercent!.toStringAsFixed(1)}%'
                        : 'N/A',
                  ),
                ),
              if (showComparison && data.previousPerformanceData != null)
                DataCell(
                  Text(
                    varianceChangeText,
                    style: TextStyle(color: varianceChangeColor),
                  ),
                ),
            ],
            onSelectChanged: (selected) {
              if (selected == true) {
                _navigateToFilteredTransactions(context, budget);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
