// lib/features/reports/presentation/pages/income_vs_expense_page.dart
import 'package:dartz/dartz.dart' show Right;
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/income_expense_bar_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart'; // For TransactionType
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/main.dart'; // Logger

class IncomeVsExpensePage extends StatefulWidget {
  const IncomeVsExpensePage({super.key});

  @override
  State<IncomeVsExpensePage> createState() => _IncomeVsExpensePageState();
}

class _IncomeVsExpensePageState extends State<IncomeVsExpensePage> {
  bool _showComparison = false;

  void _toggleComparison() {
    final newComparisonState = !_showComparison;
    setState(
        () => _showComparison = newComparisonState); // Update local state first

    // Get current period type from BLoC state
    final currentState = context.read<IncomeExpenseReportBloc>().state;
    final currentPeriod = currentState is IncomeExpenseReportLoaded
        ? currentState.reportData.periodType
        : (currentState is IncomeExpenseReportLoading)
            ? currentState.periodType
            : IncomeExpensePeriodType.monthly; // Default

    // Dispatch event with the NEW comparison state
    context.read<IncomeExpenseReportBloc>().add(LoadIncomeExpenseReport(
          compareToPrevious: newComparisonState, // Pass the toggled value
          periodType: currentPeriod,
        ));
    log.info(
        "[IncomeVsExpensePage] Toggled comparison to: $newComparisonState");
  }

  void _navigateToFilteredTransactions(BuildContext context,
      IncomeExpensePeriodData periodData, TransactionType type) {
    final filterBlocState = context.read<ReportFilterBloc>().state;
    final reportState = context.read<IncomeExpenseReportBloc>().state;
    // Ensure state is loaded before proceeding
    if (reportState is! IncomeExpenseReportLoaded) return;

    final periodType = reportState.reportData.periodType;

    DateTime periodStart = periodData.periodStart;
    DateTime periodEnd;
    if (periodType == IncomeExpensePeriodType.monthly) {
      periodEnd =
          DateTime(periodStart.year, periodStart.month + 1, 0, 23, 59, 59);
    } else {
      // Yearly
      periodEnd = DateTime(periodStart.year, 12, 31, 23, 59, 59);
    }

    final Map<String, String> filters = {
      'startDate': periodStart.toIso8601String(),
      'endDate': periodEnd.toIso8601String(),
      'type': type.name, // Pass selected type
    };
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }

    log.info(
        "[IncomeVsExpensePage] Navigating to transactions with filters: $filters");
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final modeTheme = context.modeTheme;
    final currencySymbol = settingsState.currencySymbol;

    return ReportPageWrapper(
      title: 'Income vs Expense',
      actions: [
        IconButton(
            icon: Icon(_showComparison
                ? Icons.compare_arrows_rounded
                : Icons.compare_arrows_outlined),
            tooltip: _showComparison ? "Hide Comparison" : "Compare Period",
            color: _showComparison ? theme.colorScheme.primary : null,
            onPressed: _toggleComparison),
        BlocBuilder<IncomeExpenseReportBloc, IncomeExpenseReportState>(
          builder: (context, state) {
            final currentPeriod = (state is IncomeExpenseReportLoaded)
                ? state.reportData.periodType
                : (state is IncomeExpenseReportLoading)
                    ? state.periodType
                    : IncomeExpensePeriodType.monthly;
            return PopupMenuButton<IncomeExpensePeriodType>(
                initialValue: currentPeriod,
                onSelected: (p) {
                  // When period changes, also pass current comparison state
                  context
                      .read<IncomeExpenseReportBloc>()
                      .add(LoadIncomeExpenseReport(
                        periodType: p,
                        compareToPrevious: _showComparison,
                      ));
                },
                icon: const Icon(Icons.calendar_view_month_outlined),
                tooltip: "Change Period Aggregation",
                itemBuilder: (_) => IncomeExpensePeriodType.values
                    .map((p) => PopupMenuItem<IncomeExpensePeriodType>(
                        value: p, child: Text(p.name.capitalize())))
                    .toList());
          },
        ),
      ],
      onExportCSV: () async {
        final state = context.read<IncomeExpenseReportBloc>().state;
        if (state is IncomeExpenseReportLoaded) {
          final helper = sl<CsvExportHelper>();
          return helper.exportIncomeExpenseReport(
              state.reportData, currencySymbol,
              showComparison: _showComparison);
        }
        return const Right(ExportFailure("Report data not loaded yet."));
      },
      body: BlocBuilder<IncomeExpenseReportBloc, IncomeExpenseReportState>(
        builder: (context, state) {
          if (state is IncomeExpenseReportLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is IncomeExpenseReportError)
            return Center(
                child: Text("Error: ${state.message}",
                    style: TextStyle(color: theme.colorScheme.error)));
          if (state is IncomeExpenseReportLoaded) {
            final reportData = state.reportData;
            if (reportData.periodData.isEmpty)
              return const Center(
                  child: Text("No income or expense data for this period."));

            Widget chartWidget = IncomeExpenseBarChart(
                data: reportData.periodData,
                showComparison: _showComparison,
                onTapBar: (groupIndex, rodIndex) {
                  TransactionType type;
                  if (_showComparison) {
                    // PrevIncome=0, CurrIncome=1, PrevExpense=2, CurrExpense=3
                    type = (rodIndex <= 1)
                        ? TransactionType.income
                        : TransactionType.expense;
                  } else {
                    // CurrIncome=0, CurrExpense=1
                    type = (rodIndex == 0)
                        ? TransactionType.income
                        : TransactionType.expense;
                  }
                  _navigateToFilteredTransactions(
                      context, reportData.periodData[groupIndex], type);
                });

            final bool showTable = settingsState.uiMode == UIMode.quantum &&
                (modeTheme?.preferDataTableForLists ?? false);

            return ListView(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 8.0),
                    child: SizedBox(height: 250, child: chartWidget)),
                const Divider(),
                _buildDataTable(
                    context, reportData, settingsState, _showComparison),
                const SizedBox(height: 80),
              ],
            );
          }
          return const Center(child: Text("Select filters to view report."));
        },
      ),
    );
  }

  String _formatPeriodHeader(
      DateTime date, IncomeExpensePeriodType periodType) {
    switch (periodType) {
      case IncomeExpensePeriodType.monthly:
        return DateFormat('MMM yyyy').format(date);
      case IncomeExpensePeriodType.yearly:
        return DateFormat('yyyy').format(date);
    }
  }

  Widget _buildDataTable(BuildContext context, IncomeExpenseReportData data,
      SettingsState settings, bool showComparison) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;

    List<DataColumn> columns = [
      const DataColumn(label: Text('Period')),
      const DataColumn(label: Text('Income'), numeric: true),
      const DataColumn(label: Text('Expense'), numeric: true),
      const DataColumn(label: Text('Net Flow'), numeric: true)
    ];
    if (showComparison) {
      columns.addAll([
        const DataColumn(label: Text('Prev Net'), numeric: true),
        const DataColumn(label: Text('Net Δ%'), numeric: true)
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
        rows: data.periodData.map((item) {
          final netFlow = item.netFlow;
          final netFlowColor = netFlow.currentValue >= 0
              ? Colors.green.shade700
              : theme.colorScheme.error;
          double? changePercent = netFlow.percentageChange;
          Color changeColor = theme.disabledColor;
          String changeText = "N/A";

          if (showComparison && changePercent != null) {
            if (changePercent.isInfinite) {
              changeText = changePercent.isNegative ? '-∞' : '+∞';
              changeColor = changePercent.isNegative
                  ? theme.colorScheme.error
                  : Colors.green.shade700; // Negative change is worsening
            } else if (!changePercent.isNaN) {
              changeText =
                  '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%';
              changeColor = changePercent >= 0
                  ? Colors.green.shade700
                  : theme.colorScheme.error; // Positive change is improving
            }
          }

          return DataRow(
            cells: [
              DataCell(
                  Text(_formatPeriodHeader(item.periodStart, data.periodType))),
              DataCell(
                  Text(CurrencyFormatter.format(
                      item.currentTotalIncome, currencySymbol)),
                  onTap: () => _navigateToFilteredTransactions(
                      context, item, TransactionType.income)),
              DataCell(
                  Text(CurrencyFormatter.format(
                      item.currentTotalExpense, currencySymbol)),
                  onTap: () => _navigateToFilteredTransactions(
                      context, item, TransactionType.expense)),
              DataCell(Text(
                  CurrencyFormatter.format(item.currentNetFlow, currencySymbol),
                  style: TextStyle(
                      color: netFlowColor, fontWeight: FontWeight.w500))),
              if (showComparison)
                DataCell(Text(netFlow.previousValue != null
                    ? CurrencyFormatter.format(
                        netFlow.previousValue!, currencySymbol)
                    : 'N/A')),
              if (showComparison)
                DataCell(
                    Text(changeText, style: TextStyle(color: changeColor))),
            ],
          );
        }).toList(),
      ),
    );
  }
}

extension StringCapExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
