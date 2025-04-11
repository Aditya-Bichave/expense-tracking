// lib/features/reports/presentation/pages/spending_over_time_page.dart
import 'package:dartz/dartz.dart' show Right;
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart' as df; // Alias
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/time_series_line_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart'; // For TransactionType
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/main.dart'; // Logger

class SpendingOverTimePage extends StatefulWidget {
  const SpendingOverTimePage({super.key});

  @override
  State<SpendingOverTimePage> createState() => _SpendingOverTimePageState();
}

class _SpendingOverTimePageState extends State<SpendingOverTimePage> {
  bool _showComparison = false;

  void _toggleComparison() {
    final newComparisonState = !_showComparison;
    setState(() => _showComparison = newComparisonState);
    // Get current granularity from state
    final currentGranularity = context.read<SpendingTimeReportBloc>().state
            is SpendingTimeReportLoaded
        ? (context.read<SpendingTimeReportBloc>().state
                as SpendingTimeReportLoaded)
            .reportData
            .granularity
        : (context.read<SpendingTimeReportBloc>().state
                is SpendingTimeReportLoading)
            ? (context.read<SpendingTimeReportBloc>().state
                    as SpendingTimeReportLoading)
                .granularity
            : TimeSeriesGranularity.daily; // Default

    context.read<SpendingTimeReportBloc>().add(LoadSpendingTimeReport(
          compareToPrevious: newComparisonState, // Pass new comparison state
          granularity: currentGranularity,
        ));
    log.info(
        "[SpendingOverTimePage] Toggled comparison to: $newComparisonState");
  }

  void _navigateToFilteredTransactions(BuildContext context,
      TimeSeriesDataPoint dataPoint, TimeSeriesGranularity granularity) {
    // ... (implementation unchanged) ...
    final filterBlocState = context.read<ReportFilterBloc>().state;
    DateTime periodStart = dataPoint.date;
    DateTime periodEnd;
    switch (granularity) {
      case TimeSeriesGranularity.daily:
        periodEnd = DateTime(
            periodStart.year, periodStart.month, periodStart.day, 23, 59, 59);
        break;
      case TimeSeriesGranularity.weekly:
        periodEnd = periodStart
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case TimeSeriesGranularity.monthly:
        periodEnd =
            DateTime(periodStart.year, periodStart.month + 1, 0, 23, 59, 59);
        break;
    }
    final Map<String, String> filters = {
      'startDate': periodStart.toIso8601String(),
      'endDate': periodEnd.toIso8601String(),
      'type': filterBlocState.selectedTransactionType?.name ??
          TransactionType.expense.name, // Use filter or default
    };
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }
    if (filterBlocState.selectedCategoryIds.isNotEmpty) {
      filters['categoryId'] = filterBlocState.selectedCategoryIds.join(',');
    }
    log.info(
        "[SpendingOverTimePage] Navigating to transactions with filters: $filters");
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final modeTheme = context.modeTheme;
    final currencySymbol = settingsState.currencySymbol;

    return ReportPageWrapper(
      title: 'Spending Over Time',
      actions: [
        IconButton(
            icon: Icon(_showComparison
                ? Icons.compare_arrows_rounded
                : Icons.compare_arrows_outlined),
            tooltip: _showComparison ? "Hide Comparison" : "Compare Period",
            color: _showComparison ? theme.colorScheme.primary : null,
            onPressed: _toggleComparison),
        BlocBuilder<SpendingTimeReportBloc, SpendingTimeReportState>(
          builder: (context, state) {
            final currentGranularity = (state is SpendingTimeReportLoaded)
                ? state.reportData.granularity
                : (state is SpendingTimeReportLoading)
                    ? state.granularity
                    : TimeSeriesGranularity.daily;
            return PopupMenuButton<TimeSeriesGranularity>(
                initialValue: currentGranularity,
                onSelected: (g) {
                  // When granularity changes, also pass current comparison state
                  context
                      .read<SpendingTimeReportBloc>()
                      .add(LoadSpendingTimeReport(
                        granularity: g,
                        compareToPrevious: _showComparison,
                      ));
                },
                icon: const Icon(Icons.timeline_outlined),
                tooltip: "Change Granularity",
                itemBuilder: (_) => TimeSeriesGranularity.values
                    .map((g) => PopupMenuItem<TimeSeriesGranularity>(
                        value: g, child: Text(g.name.capitalize())))
                    .toList());
          },
        ),
      ],
      onExportCSV: () async {
        final state = context.read<SpendingTimeReportBloc>().state;
        if (state is SpendingTimeReportLoaded) {
          final helper = sl<CsvExportHelper>();
          return helper.exportSpendingTimeReport(
              state.reportData, currencySymbol,
              showComparison: _showComparison);
        }
        return const Right(ExportFailure("Report data not loaded yet."));
      },
      body: BlocBuilder<SpendingTimeReportBloc, SpendingTimeReportState>(
        builder: (context, state) {
          if (state is SpendingTimeReportLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is SpendingTimeReportError)
            return Center(
                child: Text("Error: ${state.message}",
                    style: TextStyle(color: theme.colorScheme.error)));
          if (state is SpendingTimeReportLoaded) {
            final reportData = state.reportData;
            if (reportData.spendingData.isEmpty)
              return const Center(
                  child: Text("No spending data for this period."));

            Widget chartWidget = TimeSeriesLineChart(
              data: reportData.spendingData,
              granularity: reportData.granularity,
              showComparison: _showComparison,
              onTapSpot: (index) => _navigateToFilteredTransactions(context,
                  reportData.spendingData[index], reportData.granularity),
            );

            final bool showTable = settingsState.uiMode == UIMode.quantum &&
                (modeTheme?.preferDataTableForLists ?? false);

            return ListView(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 8.0),
                    child: SizedBox(height: 250, child: chartWidget)),
                const Divider(),
                if (showTable)
                  _buildDataTable(
                      context, reportData, settingsState, _showComparison)
                else
                  _buildDataList(
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

  String _formatDateHeader(DateTime date, TimeSeriesGranularity granularity) {
    switch (granularity) {
      case TimeSeriesGranularity.daily:
        return df.DateFormatter.formatDate(date);
      case TimeSeriesGranularity.weekly:
        return "Wk of ${df.DateFormatter.formatDate(date)}";
      case TimeSeriesGranularity.monthly:
        return DateFormat('MMM yyyy').format(date);
    }
  }

  Widget _buildDataList(BuildContext context, SpendingTimeReportData data,
      SettingsState settings, bool showComparison) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.spendingData.length,
      itemBuilder: (context, index) {
        final item = data.spendingData[index];
        double? changePercent = item.amount.percentageChange;
        Color changeColor = theme.disabledColor;
        String changeText = "";

        if (showComparison && changePercent != null) {
          if (changePercent.isInfinite) {
            changeText = changePercent.isNegative ? '-∞' : '+∞';
            // Spending increase is bad (red)
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

        return ListTile(
          dense: true,
          title: Text(_formatDateHeader(item.date, data.granularity)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (showComparison && changeText.isNotEmpty)
              Text(changeText,
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: changeColor)),
            if (showComparison && changeText.isNotEmpty)
              const SizedBox(width: 8),
            Text(CurrencyFormatter.format(item.currentAmount, currencySymbol)),
          ]),
          onTap: () =>
              _navigateToFilteredTransactions(context, item, data.granularity),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 0.5),
    );
  }

  Widget _buildDataTable(BuildContext context, SpendingTimeReportData data,
      SettingsState settings, bool showComparison) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;

    List<DataColumn> columns = [
      const DataColumn(label: Text('Period')),
      DataColumn(label: const Text('Total Spent'), numeric: true)
    ];
    // Add comparison columns dynamically
    if (showComparison) {
      columns.addAll([
        DataColumn(label: const Text('Prev Spent'), numeric: true),
        DataColumn(label: const Text('Change %'), numeric: true)
      ]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 42,
        columns: columns,
        rows: data.spendingData.map((item) {
          double? changePercent = item.amount.percentageChange;
          Color changeColor = theme.disabledColor;
          String changeText = "N/A";

          if (showComparison && changePercent != null) {
            if (changePercent.isInfinite) {
              changeText = changePercent.isNegative ? '-∞' : '+∞';
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
              DataCell(Text(_formatDateHeader(item.date, data.granularity))),
              DataCell(Text(CurrencyFormatter.format(
                  item.currentAmount, currencySymbol))),
              // Conditionally add comparison cells
              if (showComparison)
                DataCell(Text(item.amount.previousValue != null
                    ? CurrencyFormatter.format(
                        item.amount.previousValue!, currencySymbol)
                    : 'N/A')),
              if (showComparison)
                DataCell(
                    Text(changeText, style: TextStyle(color: changeColor))),
            ],
            onSelectChanged: (selected) {
              if (selected == true) {
                _navigateToFilteredTransactions(
                    context, item, data.granularity);
              }
            },
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
