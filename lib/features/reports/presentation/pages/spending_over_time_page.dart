import 'package:dartz/dartz.dart' as dartz;
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart' as df;
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/time_series_line_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/main.dart'; // Logger
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_divider.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';

class SpendingOverTimePage extends StatefulWidget {
  const SpendingOverTimePage({super.key});

  @override
  State<SpendingOverTimePage> createState() => _SpendingOverTimePageState();
}

class _SpendingOverTimePageState extends State<SpendingOverTimePage> {
  bool _showComparison = false;

  void _toggleComparison() {
    setState(() {
      _showComparison = !_showComparison;
    });
    final currentState = context.read<SpendingTimeReportBloc>().state;
    TimeSeriesGranularity currentGranularity = TimeSeriesGranularity.daily;
    if (currentState is SpendingTimeReportLoaded) {
      currentGranularity = currentState.reportData.granularity;
    } else if (currentState is SpendingTimeReportLoading) {
      currentGranularity = currentState.granularity;
    }

    context.read<SpendingTimeReportBloc>().add(
      LoadSpendingTimeReport(
        granularity: currentGranularity,
        compareToPrevious: _showComparison,
      ),
    );
  }

  void _navigateToFilteredTransactions(
    BuildContext context,
    TimeSeriesDataPoint point,
    TimeSeriesGranularity granularity,
  ) {
    final filterBlocState = context.read<ReportFilterBloc>().state;

    DateTime start = point.date;
    DateTime end;
    switch (granularity) {
      case TimeSeriesGranularity.daily:
        end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
        break;
      case TimeSeriesGranularity.weekly:
        end = start
            .add(const Duration(days: 7))
            .subtract(const Duration(seconds: 1));
        break;
      case TimeSeriesGranularity.monthly:
        end = DateTime(
          start.year,
          start.month + 1,
          1,
        ).subtract(const Duration(seconds: 1));
        break;
    }

    final Map<String, String> filters = {
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'type': TransactionType.expense.name,
    };
    if (filterBlocState.selectedCategoryIds.isNotEmpty) {
      filters['categoryId'] = filterBlocState.selectedCategoryIds.join(',');
    }
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }

    log.info(
      "[SpendingOverTimePage] Navigating to transactions with filters: $filters",
    );
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final settingsState = context.watch<SettingsBloc>().state;
    final uiMode = settingsState.uiMode;
    final modeTheme = context.modeTheme;
    final currencySymbol = settingsState.currencySymbol;

    return ReportPageWrapper(
      title: AppLocalizations.of(context)!.spendingOverTime,
      actions: [
        IconButton(
          icon: Icon(
            _showComparison
                ? Icons.compare_arrows_rounded
                : Icons.compare_arrows_outlined,
            color: _showComparison
                ? kit.colors.primary
                : kit.colors.textPrimary,
          ),
          tooltip: _showComparison
              ? AppLocalizations.of(context)!.hideComparison
              : AppLocalizations.of(context)!.comparePeriod,
          onPressed: _toggleComparison,
        ),
        BlocBuilder<SpendingTimeReportBloc, SpendingTimeReportState>(
          builder: (context, state) {
            final currentGranularity = (state is SpendingTimeReportLoaded)
                ? state.reportData.granularity
                : (state is SpendingTimeReportLoading)
                ? state.granularity
                : TimeSeriesGranularity.daily;
            return PopupMenuButton<TimeSeriesGranularity>(
              initialValue: currentGranularity,
              color: kit.colors.surfaceContainer,
              onSelected: (g) {
                context.read<SpendingTimeReportBloc>().add(
                  LoadSpendingTimeReport(
                    granularity: g,
                    compareToPrevious: _showComparison,
                  ),
                );
              },
              icon: Icon(
                Icons.timeline_outlined,
                color: kit.colors.textPrimary,
              ),
              tooltip: AppLocalizations.of(context)!.changeGranularity,
              itemBuilder: (_) => TimeSeriesGranularity.values
                  .map(
                    (g) => PopupMenuItem<TimeSeriesGranularity>(
                      value: g,
                      child: AppText(
                        toBeginningOfSentenceCase(g.name) ?? g.name,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
      onExportCSV: () async {
        final state = context.read<SpendingTimeReportBloc>().state;
        if (state is SpendingTimeReportLoaded) {
          final helper = sl<CsvExportHelper>();
          final result = await helper.exportSpendingTimeReport(
            state.reportData,
            currencySymbol,
            showComparison: _showComparison,
          );
          return result.fold(
            (csvString) => dartz.Right<Failure, String>(csvString),
            (failure) => dartz.Left<Failure, String>(failure),
          );
        }
        return dartz.Left<Failure, String>(
          ExportFailure(AppLocalizations.of(context)!.reportDataNotLoadedYet),
        );
      },
      body: BlocBuilder<SpendingTimeReportBloc, SpendingTimeReportState>(
        builder: (context, state) {
          if (state is SpendingTimeReportLoading)
            return const Center(child: AppLoadingIndicator());
          if (state is SpendingTimeReportError) {
            return Center(
              child: AppText(
                "Error: ${state.message}",
                color: kit.colors.error,
              ),
            );
          }
          if (state is SpendingTimeReportLoaded) {
            final reportData = state.reportData;
            if (reportData.spendingData.isEmpty) {
              return const Center(
                child: AppText("No spending data for this period."),
              );
            }

            Widget chartWidget = TimeSeriesLineChart(
              data: reportData.spendingData,
              granularity: reportData.granularity,
              showComparison: _showComparison,
              onTapSpot: (index) => _navigateToFilteredTransactions(
                context,
                reportData.spendingData[index],
                reportData.granularity,
              ),
            );

            final bool showTable =
                uiMode.name == 'quantum' &&
                (modeTheme?.preferDataTableForLists ?? false);

            return ListView(
              children: [
                Padding(
                  padding: kit.spacing.vMd.add(kit.spacing.hSm),
                  child: AspectRatio(aspectRatio: 16 / 9, child: chartWidget),
                ),
                const AppDivider(),
                if (showTable)
                  _buildDataTable(
                    context,
                    reportData,
                    settingsState,
                    _showComparison,
                  )
                else
                  _buildDataList(
                    context,
                    reportData,
                    settingsState,
                    _showComparison,
                  ),
                SizedBox(height: 80),
              ],
            );
          }
          return const Center(child: AppText("Select filters to view report."));
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

  Widget _buildDataList(
    BuildContext context,
    SpendingTimeReportData data,
    SettingsState settings,
    bool showComparison,
  ) {
    final kit = context.kit;
    final currencySymbol = settings.currencySymbol;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.spendingData.length,
      itemBuilder: (context, index) {
        final item = data.spendingData[index];
        double? changePercent = item.amount.percentageChange;
        Color changeColor = kit.colors.textMuted;
        String changeText = "";

        if (showComparison && changePercent != null) {
          if (changePercent.isInfinite) {
            changeText = changePercent.isNegative ? '-∞' : '+∞';
            changeColor = changePercent.isNegative
                ? Colors.green.shade700
                : kit.colors.error;
          } else if (!changePercent.isNaN) {
            changeText =
                '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%';
            changeColor = changePercent > 0
                ? kit.colors.error
                : Colors.green.shade700;
          }
        }

        return AppBridgeListTile(
          dense: true,
          title: AppText(
            _formatDateHeader(item.date, data.granularity),
            style: AppTextStyle.body,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showComparison && changeText.isNotEmpty)
                AppText(
                  changeText,
                  style: AppTextStyle.caption,
                  color: changeColor,
                ),
              if (showComparison && changeText.isNotEmpty)
                SizedBox(width: kit.spacing.xs),
              AppText(
                CurrencyFormatter.format(item.currentAmount, currencySymbol),
                style: AppTextStyle.body,
              ),
            ],
          ),
          onTap: () =>
              _navigateToFilteredTransactions(context, item, data.granularity),
        );
      },
      separatorBuilder: (_, __) => const AppDivider(height: 0.5),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    SpendingTimeReportData data,
    SettingsState settings,
    bool showComparison,
  ) {
    final kit = context.kit;
    final currencySymbol = settings.currencySymbol;

    List<DataColumn> columns = [
      DataColumn(label: AppText('Period', style: AppTextStyle.bodyStrong)),
      DataColumn(
        label: AppText('Total Spent', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
    ];
    if (showComparison) {
      columns.addAll([
        DataColumn(
          label: AppText('Prev Spent', style: AppTextStyle.bodyStrong),
          numeric: true,
        ),
        DataColumn(
          label: AppText('Change %', style: AppTextStyle.bodyStrong),
          numeric: true,
        ),
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
          Color changeColor = kit.colors.textMuted;
          String changeText = "N/A";

          if (showComparison && changePercent != null) {
            if (changePercent.isInfinite) {
              changeText = changePercent.isNegative ? '-∞' : '+∞';
              changeColor = changePercent.isNegative
                  ? Colors.green.shade700
                  : kit.colors.error;
            } else if (!changePercent.isNaN) {
              changeText =
                  '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%';
              changeColor = changePercent > 0
                  ? kit.colors.error
                  : Colors.green.shade700;
            }
          }

          return DataRow(
            cells: [
              DataCell(AppText(_formatDateHeader(item.date, data.granularity))),
              DataCell(
                AppText(
                  CurrencyFormatter.format(item.currentAmount, currencySymbol),
                ),
              ),
              if (showComparison)
                DataCell(
                  AppText(
                    item.amount.previousValue != null
                        ? CurrencyFormatter.format(
                            item.amount.previousValue!,
                            currencySymbol,
                          )
                        : 'N/A',
                  ),
                ),
              if (showComparison)
                DataCell(AppText(changeText, color: changeColor)),
            ],
            onSelectChanged: (selected) {
              if (selected == true) {
                SystemSound.play(SystemSoundType.click);
                _navigateToFilteredTransactions(
                  context,
                  item,
                  data.granularity,
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
