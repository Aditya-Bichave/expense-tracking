// lib/features/reports/presentation/pages/spending_by_category_page.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/spending_bar_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/spending_pie_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpendingByCategoryPage extends StatefulWidget {
  const SpendingByCategoryPage({super.key});

  @override
  State<SpendingByCategoryPage> createState() => _SpendingByCategoryPageState();
}

class _SpendingByCategoryPageState extends State<SpendingByCategoryPage> {
  bool _showPieChart = true; // Default to pie chart

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final uiMode = settingsState.uiMode;
    final modeTheme = context.modeTheme;
    final bool preferTables = modeTheme?.preferDataTableForLists ?? false;
    final bool showAlternateChartOption =
        uiMode != UIMode.aether; // No bar chart toggle for Aether

    return ReportPageWrapper(
      title: 'Spending by Category',
      // Add chart toggle button to actions if applicable
      actions: showAlternateChartOption
          ? [
              IconButton(
                  icon: Icon(_showPieChart
                      ? Icons.bar_chart_rounded
                      : Icons.pie_chart_outline_rounded),
                  tooltip: _showPieChart ? "Show Bar Chart" : "Show Pie Chart",
                  onPressed: () =>
                      setState(() => _showPieChart = !_showPieChart)),
            ]
          : [],
      body:
          BlocBuilder<SpendingCategoryReportBloc, SpendingCategoryReportState>(
        builder: (context, state) {
          if (state is SpendingCategoryReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SpendingCategoryReportError) {
            return Center(
                child: Text("Error: ${state.message}",
                    style: TextStyle(color: theme.colorScheme.error)));
          }
          if (state is SpendingCategoryReportLoaded) {
            final reportData = state.reportData;
            if (reportData.spendingByCategory.isEmpty) {
              return const Center(
                  child: Text("No spending data for this period."));
            }

            // Determine which chart to show
            Widget chartWidget;
            if (_showPieChart && uiMode != UIMode.quantum) {
              // Pie for Elemental/Aether
              chartWidget =
                  SpendingPieChart(data: reportData.spendingByCategory);
            } else {
              // Bar for Quantum or if toggled
              chartWidget =
                  SpendingBarChart(data: reportData.spendingByCategory);
            }

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    height: 250, // Adjust height as needed
                    child: chartWidget,
                  ),
                ),
                const Divider(),
                _buildDataTable(context, reportData, settingsState),
                const SizedBox(height: 80), // Space for potential FAB/controls
              ],
            );
          }
          return const Center(child: Text("Select filters to view report."));
        },
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, SpendingCategoryReportData data,
      SettingsState settings) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;

    return DataTable(
      columnSpacing: 16,
      headingRowHeight: 36,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 42,
      columns: const [
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Amount'), numeric: true),
        DataColumn(label: Text('%'), numeric: true),
      ],
      rows: data.spendingByCategory.map((item) {
        return DataRow(
          cells: [
            DataCell(Row(
              children: [
                Icon(Icons.circle, color: item.categoryColor, size: 12),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(item.categoryName,
                        overflow: TextOverflow.ellipsis)),
              ],
            )),
            DataCell(Text(
                CurrencyFormatter.format(item.totalAmount, currencySymbol))),
            DataCell(Text('${(item.percentage * 100).toStringAsFixed(1)}%')),
          ],
          // TODO: Add onTap for drill-down
          onSelectChanged: (selected) {
            if (selected == true) {
              log.info(
                  "Drill-down requested for category: ${item.categoryName}");
              // context.read<TransactionListBloc>().add(FilterChanged(categoryId: item.categoryId));
              // context.go(RouteNames.transactionsList); // Navigate to filtered list
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "Drill-down for ${item.categoryName} (Not Implemented)")));
            }
          },
        );
      }).toList(),
    );
  }
}
