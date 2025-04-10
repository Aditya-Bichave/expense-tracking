// lib/features/reports/presentation/pages/income_vs_expense_page.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/income_expense_bar_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class IncomeVsExpensePage extends StatelessWidget {
  const IncomeVsExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final modeTheme = context.modeTheme;

    return ReportPageWrapper(
      title: 'Income vs Expense',
      actions: [
        BlocBuilder<IncomeExpenseReportBloc, IncomeExpenseReportState>(
          builder: (context, state) {
            final currentPeriod = (state is IncomeExpenseReportLoaded)
                ? state.reportData.periodType
                : (state is IncomeExpenseReportLoading)
                    ? state.periodType
                    : IncomeExpensePeriodType.monthly; // Default

            return PopupMenuButton<IncomeExpensePeriodType>(
              initialValue: currentPeriod,
              onSelected: (IncomeExpensePeriodType newPeriod) {
                context
                    .read<IncomeExpenseReportBloc>()
                    .add(ChangeIncomeExpensePeriod(newPeriod));
              },
              icon: const Icon(Icons.calendar_view_month_outlined),
              tooltip: "Change Period Aggregation",
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<IncomeExpensePeriodType>>[
                const PopupMenuItem<IncomeExpensePeriodType>(
                  value: IncomeExpensePeriodType.monthly,
                  child: Text('Monthly'),
                ),
                const PopupMenuItem<IncomeExpensePeriodType>(
                  value: IncomeExpensePeriodType.yearly,
                  child: Text('Yearly'),
                ),
              ],
            );
          },
        ),
      ],
      body: BlocBuilder<IncomeExpenseReportBloc, IncomeExpenseReportState>(
        builder: (context, state) {
          if (state is IncomeExpenseReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is IncomeExpenseReportError) {
            return Center(
                child: Text("Error: ${state.message}",
                    style: TextStyle(color: theme.colorScheme.error)));
          }
          if (state is IncomeExpenseReportLoaded) {
            final reportData = state.reportData;
            if (reportData.periodData.isEmpty) {
              return const Center(
                  child: Text("No income or expense data for this period."));
            }

            // Decide on chart type - Bar chart is good for comparison
            Widget chartWidget =
                IncomeExpenseBarChart(data: reportData.periodData);

            final bool showTable = settingsState.uiMode == UIMode.quantum &&
                (modeTheme?.preferDataTableForLists ?? false);

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: SizedBox(
                    height: 250, // Adjust height
                    child: chartWidget,
                  ),
                ),
                const Divider(),
                _buildDataTable(context, reportData, settingsState),
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
        return DateFormat('MMM yyyy').format(date); // Jan 2024
      case IncomeExpensePeriodType.yearly:
        return DateFormat('yyyy').format(date); // 2024
    }
  }

  Widget _buildDataTable(BuildContext context, IncomeExpenseReportData data,
      SettingsState settings) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;

    return SingleChildScrollView(
      // Ensure table is scrollable horizontally
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 42,
        columns: const [
          DataColumn(label: Text('Period')),
          DataColumn(label: Text('Income'), numeric: true),
          DataColumn(label: Text('Expense'), numeric: true),
          DataColumn(label: Text('Net Flow'), numeric: true),
        ],
        rows: data.periodData.map((item) {
          final netFlow = item.netFlow;
          final netFlowColor =
              netFlow >= 0 ? Colors.green.shade700 : theme.colorScheme.error;
          return DataRow(
            cells: [
              DataCell(
                  Text(_formatPeriodHeader(item.periodStart, data.periodType))),
              DataCell(Text(
                  CurrencyFormatter.format(item.totalIncome, currencySymbol))),
              DataCell(Text(
                  CurrencyFormatter.format(item.totalExpense, currencySymbol))),
              DataCell(Text(CurrencyFormatter.format(netFlow, currencySymbol),
                  style: TextStyle(
                      color: netFlowColor, fontWeight: FontWeight.w500))),
            ],
            // TODO: Add drill-down on tap?
            // onSelectChanged: (selected) {
            //   if (selected == true) {
            //     // Navigate to transactions for this period
            //   }
            // },
          );
        }).toList(),
      ),
    );
  }
}
