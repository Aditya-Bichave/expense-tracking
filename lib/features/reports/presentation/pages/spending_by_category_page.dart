import 'package:dartz/dartz.dart' hide State;
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/spending_bar_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/spending_pie_chart.dart';
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
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_divider.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';

class SpendingByCategoryPage extends StatefulWidget {
  const SpendingByCategoryPage({super.key});

  @override
  State<SpendingByCategoryPage> createState() => _SpendingByCategoryPageState();
}

class _SpendingByCategoryPageState extends State<SpendingByCategoryPage> {
  bool _showComparison = false;
  bool _showPieChart = true;

  void _toggleComparison() {
    setState(() {
      _showComparison = !_showComparison;
    });
  }

  void _navigateToFilteredTransactions(
    BuildContext context,
    CategorySpendingData categoryData,
  ) {
    final filterBlocState = context.read<ReportFilterBloc>().state;
    final Map<String, String> filters = {
      'startDate': filterBlocState.startDate.toIso8601String(),
      'endDate': filterBlocState.endDate.toIso8601String(),
      'type': TransactionType.expense.name,
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
    final kit = context.kit;
    final settingsState = context.watch<SettingsBloc>().state;
    final uiMode = settingsState.uiMode;

    final bool useBarChart =
        uiMode.name == 'quantum' || _showComparison || !_showPieChart;
    final bool showAlternateChartOption =
        uiMode.name != 'aether' && !_showComparison;
    final currencySymbol = settingsState.currencySymbol;

    return ReportPageWrapper(
      title: AppLocalizations.of(context)!.spendingByCategory,
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
        if (showAlternateChartOption)
          IconButton(
            icon: Icon(
              useBarChart
                  ? Icons.pie_chart_outline_rounded
                  : Icons.bar_chart_rounded,
              color: kit.colors.textPrimary,
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
          final result = await helper.exportSpendingCategoryReport(
            state.reportData,
            currencySymbol,
            showComparison: _showComparison,
          );
          return result.fold(
            (csvString) => Right(csvString),
            (failure) => Left(failure),
          );
        }
        return Left(
          ExportFailure(AppLocalizations.of(context)!.reportDataNotLoadedYet),
        );
      },
      body:
          BlocBuilder<SpendingCategoryReportBloc, SpendingCategoryReportState>(
            builder: (context, state) {
              if (state is SpendingCategoryReportLoading) {
                return const Center(child: AppLoadingIndicator());
              }
              if (state is SpendingCategoryReportError) {
                return Center(
                  child: AppText(
                    "Error: ${state.message}",
                    color: kit.colors.error,
                  ),
                );
              }
              if (state is SpendingCategoryReportLoaded) {
                final reportData = state.reportData;
                if (reportData.spendingByCategory.isEmpty) {
                  return Center(
                    child: AppText(
                      "No spending data for this period.",
                      color: kit.colors.textSecondary,
                    ),
                  );
                }

                Widget chartWidget;
                if (useBarChart) {
                  chartWidget = SpendingBarChart(
                    data: reportData.spendingByCategory,
                    previousData:
                        (_showComparison &&
                            reportData.previousSpendingByCategory != null)
                        ? reportData.previousSpendingByCategory
                        : null,
                    onTapBar: (index) => _navigateToFilteredTransactions(
                      context,
                      reportData.spendingByCategory[index],
                    ),
                  );
                } else {
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
                      padding: kit.spacing.vMd,
                      child: SizedBox(height: 250, child: chartWidget),
                    ),
                    const AppDivider(),
                    _buildDataTable(
                      context,
                      reportData,
                      settingsState,
                      _showComparison,
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
    SpendingCategoryReportData data,
    SettingsState settings,
    bool showComparison,
  ) {
    final kit = context.kit;
    final currencySymbol = settings.currencySymbol;
    final percentFormat = NumberFormat('##0.0%');

    List<DataColumn> columns = [
      DataColumn(label: AppText('Category', style: AppTextStyle.bodyStrong)),
      DataColumn(
        label: AppText('Amount', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
      DataColumn(
        label: AppText('%', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
    ];
    if (showComparison && data.previousSpendingByCategory != null) {
      columns.addAll([
        DataColumn(
          label: AppText('Prev Amt', style: AppTextStyle.bodyStrong),
          numeric: true,
        ),
        DataColumn(
          label: AppText('Change %', style: AppTextStyle.bodyStrong),
          numeric: true,
        ),
      ]);
    }

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
              DataCell(
                Row(
                  children: [
                    Icon(Icons.circle, color: item.categoryColor, size: 12),
                    SizedBox(width: kit.spacing.xs),
                    Expanded(
                      child: AppText(
                        item.categoryName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                AppText(
                  CurrencyFormatter.format(
                    item.currentTotalAmount,
                    currencySymbol,
                  ),
                ),
              ),
              DataCell(AppText(percentFormat.format(item.percentage))),
              if (showComparison && data.previousSpendingByCategory != null)
                DataCell(
                  AppText(
                    amountComp.previousValue != null
                        ? CurrencyFormatter.format(
                            amountComp.previousValue!,
                            currencySymbol,
                          )
                        : 'N/A',
                  ),
                ),
              if (showComparison && data.previousSpendingByCategory != null)
                DataCell(AppText(changeText, color: changeColor)),
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
