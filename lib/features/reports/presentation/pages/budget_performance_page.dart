// lib/features/reports/presentation/pages/budget_performance_page.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Added for CSV Helper
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart'; // Added
import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart'; // Import filter bloc
import 'package:expense_tracker/features/reports/presentation/widgets/charts/budget_performance_bar_chart.dart'; // Specific chart
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // For percentage format
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';

class BudgetPerformancePage extends StatelessWidget {
  const BudgetPerformancePage({super.key});

  // --- Drill Down Function ---
  void _navigateToFilteredTransactions(BuildContext context, Budget budget) {
    final filterBlocState = context.read<ReportFilterBloc>().state;
    final (start, end) = budget.getCurrentPeriodDates();

    final Map<String, String> filters = {
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'type': TransactionType.expense.name,
    };
    if (budget.categoryIds != null && budget.categoryIds!.isNotEmpty) {
      filters['categoryId'] = budget.categoryIds!.join(',');
    }
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }

    log.info(
        "[BudgetPerformancePage] Navigating to transactions with filters: $filters");
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    return ReportPageWrapper(
      title: 'Budget Performance',
      actions: [
        BlocBuilder<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
          builder: (context, state) {
            final bool showComparison = state is BudgetPerformanceReportLoaded
                ? state.showComparison
                : false;
            final bool canCompare = state is BudgetPerformanceReportLoaded &&
                state.reportData.previousPerformanceData != null;
            return IconButton(
              icon: Icon(showComparison
                  ? Icons.compare_arrows_rounded
                  : Icons.compare_arrows_outlined),
              tooltip: showComparison
                  ? "Hide Comparison"
                  : "Compare to Previous Period",
              color: showComparison ? theme.colorScheme.primary : null,
              onPressed: canCompare || showComparison
                  ? () => context
                      .read<BudgetPerformanceReportBloc>()
                      .add(const ToggleBudgetComparison())
                  : null,
            );
          },
        ),
      ],
      onExportCSV: () async {
        final state = context.read<BudgetPerformanceReportBloc>().state;
        if (state is BudgetPerformanceReportLoaded) {
          final helper = sl<CsvExportHelper>();
          // TODO: Add logic to include comparison data in CSV if showComparison is true
          return helper.exportBudgetPerformanceReport(
              state.reportData, currencySymbol);
        }
        return const Right(ExportFailure("Report data not loaded yet."));
      },
      body: BlocBuilder<BudgetPerformanceReportBloc,
          BudgetPerformanceReportState>(
        builder: (context, state) {
          if (state is BudgetPerformanceReportLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is BudgetPerformanceReportError)
            return Center(
                child: Text("Error: ${state.message}",
                    style: TextStyle(color: theme.colorScheme.error)));
          if (state is BudgetPerformanceReportLoaded) {
            final reportData = state.reportData;
            if (reportData.performanceData.isEmpty)
              return const Center(
                  child: Text("No budgets found for this period."));
            final bool showComparison = state.showComparison &&
                reportData.previousPerformanceData != null;
            return ListView(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 8.0),
                    child: SizedBox(
                        height: 250,
                        child: BudgetPerformanceBarChart(
                            data: reportData.performanceData,
                            previousData: showComparison
                                ? reportData.previousPerformanceData
                                : null,
                            currencySymbol: currencySymbol))),
                const Divider(),
                _buildDataTable(
                    context, reportData, settingsState, showComparison),
                const SizedBox(height: 80),
              ],
            );
          }
          return const Center(child: Text("Select filters to view report."));
        },
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, BudgetPerformanceReportData data,
      SettingsState settings, bool showComparison) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;
    final percentFormat = NumberFormat('##0.0%');

    final Map<String, BudgetPerformanceData> previousDataMap = showComparison &&
            data.previousPerformanceData != null
        ? {for (var item in data.previousPerformanceData!) item.budget.id: item}
        : {};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 36,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 48,
        columns: [
          const DataColumn(label: Text('Budget')),
          const DataColumn(label: Text('Target'), numeric: true),
          const DataColumn(label: Text('Actual'), numeric: true),
          const DataColumn(label: Text('Variance'), numeric: true),
          if (showComparison)
            const DataColumn(label: Text('Prev Var'), numeric: true),
          if (showComparison)
            const DataColumn(label: Text('Var Δ%'), numeric: true),
        ],
        rows: data.performanceData.map((item) {
          final budget = item.budget;
          final varianceColor = item.varianceAmount >= 0
              ? Colors.green.shade700
              : theme.colorScheme.error;
          double? prevVariance = showComparison
              ? previousDataMap[budget.id]?.varianceAmount
              : null;
          double? varianceChangePercent;
          if (showComparison && prevVariance != null) {
            if (prevVariance == 0) {
              varianceChangePercent = item.varianceAmount == 0
                  ? 0.0
                  : (item.varianceAmount > 0
                      ? double.infinity
                      : double.negativeInfinity);
            } else {
              varianceChangePercent =
                  ((item.varianceAmount - prevVariance) / prevVariance.abs()) *
                      100;
            }
          }
          String varianceChangeText = 'N/A';
          Color varianceChangeColor = theme.disabledColor;
          if (varianceChangePercent != null) {
            if (varianceChangePercent.isInfinite) {
              // --- FIXED: Use isNegative instead of isSignMinus ---
              varianceChangeText =
                  varianceChangePercent.isNegative ? '-∞' : '+∞';
              varianceChangeColor = varianceChangePercent.isNegative
                  ? theme.colorScheme.error
                  : Colors.green.shade700;
              // --- END FIX ---
            } else {
              varianceChangeText =
                  '${varianceChangePercent > 0 ? '+' : ''}${varianceChangePercent.toStringAsFixed(0)}%';
              varianceChangeColor = varianceChangePercent >= 0
                  ? Colors.green.shade700
                  : theme.colorScheme.error;
            }
          }
          return DataRow(
            cells: [
              DataCell(Text(budget.name, overflow: TextOverflow.ellipsis)),
              DataCell(Text(CurrencyFormatter.format(
                  budget.targetAmount, currencySymbol))),
              DataCell(Text(CurrencyFormatter.format(
                  item.actualSpending, currencySymbol))),
              DataCell(Text(
                  CurrencyFormatter.format(item.varianceAmount, currencySymbol),
                  style: TextStyle(color: varianceColor))),
              if (showComparison)
                DataCell(Text(
                    prevVariance != null
                        ? CurrencyFormatter.format(prevVariance, currencySymbol)
                        : 'N/A',
                    style: TextStyle(
                        color: prevVariance == null
                            ? theme.disabledColor
                            : (prevVariance >= 0
                                ? Colors.green.shade700
                                : theme.colorScheme.error)))),
              if (showComparison)
                DataCell(Text(varianceChangeText,
                    style: TextStyle(color: varianceChangeColor))),
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
