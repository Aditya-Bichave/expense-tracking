// lib/features/reports/presentation/pages/spending_by_category_page.dart
import 'package:dartz/dartz.dart' show Right;
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/spending_bar_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/spending_pie_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';

class SpendingByCategoryPage extends StatefulWidget {
  const SpendingByCategoryPage({super.key});

  @override
  State<SpendingByCategoryPage> createState() => _SpendingByCategoryPageState();
}

class _SpendingByCategoryPageState extends State<SpendingByCategoryPage> {
  bool _showPieChart = true; // Default remains pie chart for non-Quantum
  bool _showComparison = false;

  void _toggleComparison() {
    final newComparisonState = !_showComparison;
    setState(() => _showComparison = newComparisonState);
    context.read<SpendingCategoryReportBloc>().add(
      LoadSpendingCategoryReport(compareToPrevious: newComparisonState),
    ); // Pass the flag
    log.info(
      "[SpendingByCategoryPage] Toggled comparison to: $newComparisonState",
    );
  }

  void _navigateToFilteredTransactions(
    BuildContext context,
    CategorySpendingData categoryData,
  ) {
    final filterBlocState = context.read<ReportFilterBloc>().state;
    final Map<String, String> filters = {
      'startDate': filterBlocState.startDate.toIso8601String(),
      'endDate': filterBlocState.endDate.toIso8601String(),
      'type': TransactionType.expense.name, // Spending report is always expense
      'categoryId': categoryData.categoryId,
    };
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }
    log.info(
      "[SpendingByCategoryPage] Navigating to transactions with filters: $filters",
    );
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final uiMode = settingsState.uiMode;
    final modeTheme = context.modeTheme;
    final bool preferTables = modeTheme?.preferDataTableForLists ?? false;
    // Bar chart is default for Quantum, or if comparison active, or if toggled
    final bool useBarChart =
        uiMode == UIMode.quantum || _showComparison || !_showPieChart;
    final bool showAlternateChartOption =
        uiMode != UIMode.aether &&
        !_showComparison; // Can toggle if not Aether and not comparing
    final currencySymbol = settingsState.currencySymbol;

    return ReportPageWrapper(
      title: AppLocalizations.of(context)!.spendingByCategory,
      actions: [
        IconButton(
          icon: Icon(
            _showComparison
                ? Icons.compare_arrows_rounded
                : Icons.compare_arrows_outlined,
          ),
          tooltip: _showComparison
              ? AppLocalizations.of(context)!.hideComparison
              : AppLocalizations.of(context)!.comparePeriod,
          color: _showComparison ? theme.colorScheme.primary : null,
          onPressed: _toggleComparison,
        ),
        if (showAlternateChartOption)
          IconButton(
            icon: Icon(
              useBarChart
                  ? Icons.pie_chart_outline_rounded
                  : Icons.bar_chart_rounded,
            ),
            tooltip: useBarChart
                ? AppLocalizations.of(context)!.showPieChart
                : AppLocalizations.of(context)!.showBarChart,
            onPressed: () => setState(() => _showPieChart = !_showPieChart),
          ),
      ],
      onExportCSV: () async {
        final state = context.read<SpendingCategoryReportBloc>().state;
        if (state is SpendingCategoryReportLoaded) {
          final helper = sl<CsvExportHelper>();
          return helper.exportSpendingCategoryReport(
            state.reportData,
            currencySymbol,
            showComparison: _showComparison,
          );
        }
        return Right(
          ExportFailure(AppLocalizations.of(context)!.reportDataNotLoadedYet),
        );
      },
      body:
          BlocBuilder<SpendingCategoryReportBloc, SpendingCategoryReportState>(
            builder: (context, state) {
              if (state is SpendingCategoryReportLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SpendingCategoryReportError) {
                return Center(
                  child: Text(
                    "Error: ${state.message}",
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }
              if (state is SpendingCategoryReportLoaded) {
                final reportData = state.reportData;
                if (reportData.spendingByCategory.isEmpty) {
                  return const Center(
                    child: Text("No spending data for this period."),
                  );
                }

            Widget chartWidget;
            if (useBarChart) {
              chartWidget = SpendingBarChart(
                data: reportData.spendingByCategory,
                // Pass previous data if comparison is active
                previousData: (_showComparison &&
                        reportData.previousSpendingByCategory != null)
                    ? reportData.previousSpendingByCategory
                    : null,
                onTapBar: (index) => _navigateToFilteredTransactions(
                  context,
                  reportData.spendingByCategory[index],
                ),
              );
            } else {
              // Pie Chart for Elemental/Aether (no comparison shown on pie)
              chartWidget = SpendingPieChart(
                data: reportData.spendingByCategory,
                onTapSlice: (index) => _navigateToFilteredTransactions(
                  context,
                  reportData.spendingByCategory[index],
                ),
              );
            }

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(height: 250, child: chartWidget),
                ),
                const Divider(),
                _buildDataTable(
                  context,
                  reportData,
                  settingsState,
                  _showComparison,
                ), // Pass comparison flag
                const SizedBox(height: 80),
              ],
            );
          }
          return const Center(
            child: Text("Select filters to view report."),
          );
        },
      ),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    SpendingCategoryReportData data,
    SettingsState settings,
    bool showComparison,
  ) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;
    final percentFormat = NumberFormat('##0.0%');

    List<DataColumn> columns = const [
      DataColumn(label: Text('Category')),
      DataColumn(label: Text('Amount'), numeric: true),
      DataColumn(label: Text('%'), numeric: true),
    ];
    // Add comparison columns dynamically
    if (showComparison && data.previousSpendingByCategory != null) {
      columns.addAll([
        const DataColumn(label: Text('Prev Amt'), numeric: true),
        const DataColumn(label: Text('Change %'), numeric: true),
      ]);
    }

    // Create a map for quick lookup of previous data
    final Map<String, CategorySpendingData> previousDataMap =
        (showComparison && data.previousSpendingByCategory != null)
        ? {
            for (var item in data.previousSpendingByCategory!)
              item.categoryId: item,
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
        rows: data.spendingByCategory.map((item) {
          final prevItem = previousDataMap[item.categoryId];
          final ComparisonValue<double> amountComp = ComparisonValue(
            currentValue: item.currentTotalAmount,
            previousValue: prevItem?.currentTotalAmount,
          );
          double? changePercent = amountComp.percentageChange;
          Color changeColor = theme.disabledColor;
          String changeText = "N/A";

          if (showComparison && changePercent != null) {
            if (changePercent.isInfinite) {
              changeText = changePercent.isNegative ? '-∞' : '+∞';
              // Spending increase is bad (red), decrease is good (green)
              changeColor = changePercent.isNegative
                  ? Colors.green.shade700
                  : theme.colorScheme.error;
            } else if (!changePercent.isNaN) {
              changeText =
                  '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%';
              changeColor = changePercent > 0
                  ? theme.colorScheme.error
                  : Colors.green.shade700;
            }
          }
          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    Icon(Icons.circle, color: item.categoryColor, size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.categoryName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  CurrencyFormatter.format(
                    item.currentTotalAmount,
                    currencySymbol,
                  ),
                ),
              ),
              DataCell(Text(percentFormat.format(item.percentage))),
              // Conditionally add comparison cells
              if (showComparison && data.previousSpendingByCategory != null)
                DataCell(
                  Text(
                    amountComp.previousValue != null
                        ? CurrencyFormatter.format(
                            amountComp.previousValue!,
                            currencySymbol,
                          )
                        : 'N/A',
                  ),
                ),
              if (showComparison && data.previousSpendingByCategory != null)
                DataCell(
                  Text(changeText, style: TextStyle(color: changeColor)),
                ),
            ],
            onSelectChanged: (selected) {
              if (selected == true) {
                SystemSound.play(SystemSoundType.click);
                _navigateToFilteredTransactions(context, item);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
