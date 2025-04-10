// lib/features/reports/presentation/pages/spending_over_time_page.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/spending_bar_chart.dart'; // Can use for daily/weekly bars
import 'package:expense_tracker/features/reports/presentation/widgets/charts/time_series_line_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SpendingOverTimePage extends StatefulWidget {
  const SpendingOverTimePage({super.key});

  @override
  State<SpendingOverTimePage> createState() => _SpendingOverTimePageState();
}

class _SpendingOverTimePageState extends State<SpendingOverTimePage> {
  // Could add state for chart type toggle (line vs bar) if desired

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final modeTheme = context.modeTheme;

    return ReportPageWrapper(
      title: 'Spending Over Time',
      // Add Granularity Toggle Button
      actions: [
        BlocBuilder<SpendingTimeReportBloc, SpendingTimeReportState>(
          builder: (context, state) {
            final currentGranularity = (state is SpendingTimeReportLoaded)
                ? state.reportData.granularity
                : (state is SpendingTimeReportLoading)
                    ? state.granularity
                    : TimeSeriesGranularity.daily; // Default

            return PopupMenuButton<TimeSeriesGranularity>(
              initialValue: currentGranularity,
              onSelected: (TimeSeriesGranularity newGranularity) {
                context
                    .read<SpendingTimeReportBloc>()
                    .add(ChangeGranularity(newGranularity));
              },
              icon: const Icon(Icons
                  .timeline_outlined), // Or Icons.calendar_view_month, etc.
              tooltip: "Change Granularity",
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<TimeSeriesGranularity>>[
                const PopupMenuItem<TimeSeriesGranularity>(
                  value: TimeSeriesGranularity.daily,
                  child: Text('Daily'),
                ),
                const PopupMenuItem<TimeSeriesGranularity>(
                  value: TimeSeriesGranularity.weekly,
                  child: Text('Weekly'),
                ),
                const PopupMenuItem<TimeSeriesGranularity>(
                  value: TimeSeriesGranularity.monthly,
                  child: Text('Monthly'),
                ),
              ],
            );
          },
        ),
      ],
      body: BlocBuilder<SpendingTimeReportBloc, SpendingTimeReportState>(
        builder: (context, state) {
          if (state is SpendingTimeReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SpendingTimeReportError) {
            return Center(
                child: Text("Error: ${state.message}",
                    style: TextStyle(color: theme.colorScheme.error)));
          }
          if (state is SpendingTimeReportLoaded) {
            final reportData = state.reportData;
            if (reportData.spendingData.isEmpty) {
              return const Center(
                  child: Text("No spending data for this period."));
            }

            // Determine chart type based on granularity or UI mode if needed
            Widget chartWidget = TimeSeriesLineChart(
                data: reportData.spendingData,
                granularity: reportData.granularity);

            // Optional: Table View for Quantum?
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
                if (showTable)
                  _buildDataTable(context, reportData, settingsState)
                else // Show a simpler summary list for other modes
                  _buildDataList(context, reportData, settingsState),
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
        return DateFormatter.formatDate(date); // YYYY-MM-DD
      case TimeSeriesGranularity.weekly:
        // Show start date of the week
        return "Wk of ${DateFormatter.formatDate(date)}";
      case TimeSeriesGranularity.monthly:
        return DateFormat('MMM yyyy').format(date); // Jan 2024
    }
  }

  // Simple list for non-table view
  Widget _buildDataList(BuildContext context, SpendingTimeReportData data,
      SettingsState settings) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.spendingData.length,
      itemBuilder: (context, index) {
        final item = data.spendingData[index];
        return ListTile(
          dense: true,
          title: Text(_formatDateHeader(item.date, data.granularity)),
          trailing: Text(CurrencyFormatter.format(item.amount, currencySymbol)),
          // TODO: Add drill-down on tap?
          // onTap: () => // Navigate to transactions for this period
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 0.5),
    );
  }

  // Data Table for Quantum Mode
  Widget _buildDataTable(BuildContext context, SpendingTimeReportData data,
      SettingsState settings) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;

    return DataTable(
      columnSpacing: 16,
      headingRowHeight: 36,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 42,
      columns: const [
        DataColumn(label: Text('Period')),
        DataColumn(label: Text('Total Spent'), numeric: true),
      ],
      rows: data.spendingData.map((item) {
        return DataRow(
          cells: [
            DataCell(Text(_formatDateHeader(item.date, data.granularity))),
            DataCell(
                Text(CurrencyFormatter.format(item.amount, currencySymbol))),
          ],
          // TODO: Add drill-down on tap?
          // onSelectChanged: (selected) {
          //    if (selected == true) {
          //      // Navigate to transactions for this period
          //    }
          // },
        );
      }).toList(),
    );
  }
}
