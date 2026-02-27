import 'package:dartz/dartz.dart' hide State;
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
// import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_event.dart'; // Use main bloc import
// import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_state.dart'; // Use main bloc import
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/income_expense_bar_chart.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/core/constants/route_names.dart'; // Fixed import
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart'; // Fixed import for TransactionType
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/main.dart'; // Logger
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart'; // Needed for modeTheme
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_divider.dart';
import 'package:expense_tracker/core/error/failure.dart'; // Import Failure
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart'; // If needed for UiMode logic

class IncomeVsExpensePage extends StatefulWidget {
  const IncomeVsExpensePage({super.key});

  @override
  State<IncomeVsExpensePage> createState() => _IncomeVsExpensePageState();
}

class _IncomeVsExpensePageState extends State<IncomeVsExpensePage> {
  bool _showComparison = false;

  void _toggleComparison() {
    setState(() {
      _showComparison = !_showComparison;
    });
    // Trigger reload with comparison flag
    final currentState = context.read<IncomeExpenseReportBloc>().state;
    IncomeExpensePeriodType currentPeriod = IncomeExpensePeriodType.monthly;
    if (currentState is IncomeExpenseReportLoaded) {
      currentPeriod = currentState.reportData.periodType;
    } else if (currentState is IncomeExpenseReportLoading) {
      currentPeriod = currentState.periodType;
    }

    context.read<IncomeExpenseReportBloc>().add(
      LoadIncomeExpenseReport(
        periodType: currentPeriod,
        compareToPrevious: _showComparison,
      ),
    );
  }

  void _navigateToFilteredTransactions(
    BuildContext context,
    IncomeExpensePeriodData periodData,
    TransactionType? type,
  ) {
    Map<String, String> filters = {};

    // Date Range: Start and End of the specific period bar
    filters['startDate'] = periodData.periodStart.toIso8601String();

    // Calculate periodEnd based on periodType.
    // IncomeExpensePeriodData doesn't strictly define periodEnd in the entity I cat'ed earlier,
    // so we calculate it here based on periodType context from bloc if available,
    // or infer it.
    // The entity has periodStart.
    // If monthly, end is end of month. If yearly, end of year.
    // We can infer from the state.
    final state = context.read<IncomeExpenseReportBloc>().state;
    IncomeExpensePeriodType periodType = IncomeExpensePeriodType.monthly;
    if (state is IncomeExpenseReportLoaded) {
      periodType = state.reportData.periodType;
    }

    DateTime endDate;
    if (periodType == IncomeExpensePeriodType.monthly) {
      endDate = DateTime(
        periodData.periodStart.year,
        periodData.periodStart.month + 1,
        0,
        23,
        59,
        59,
      );
    } else {
      endDate = DateTime(periodData.periodStart.year, 12, 31, 23, 59, 59);
    }
    filters['endDate'] = endDate.toIso8601String();

    // Transaction Type
    if (type != null) {
      filters['type'] = type.name; // 'income' or 'expense'
    }

    // Inherit global filters (Account, Category)
    final filterBlocState = context.read<ReportFilterBloc>().state;
    if (filterBlocState.selectedCategoryIds.isNotEmpty) {
      filters['categoryId'] = filterBlocState.selectedCategoryIds.join(',');
    }
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }

    log.info(
      "[IncomeVsExpensePage] Navigating to transactions with filters: $filters",
    );
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    return ReportPageWrapper(
      title: AppLocalizations.of(context)!.incomeVsExpense,
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
        BlocBuilder<IncomeExpenseReportBloc, IncomeExpenseReportState>(
          builder: (context, state) {
            final currentPeriod = (state is IncomeExpenseReportLoaded)
                ? state.reportData.periodType
                : (state is IncomeExpenseReportLoading)
                ? state.periodType
                : IncomeExpensePeriodType.monthly;
            return PopupMenuButton<IncomeExpensePeriodType>(
              initialValue: currentPeriod,
              color: kit.colors.surfaceContainer,
              onSelected: (p) {
                // When period changes, also pass current comparison state
                context.read<IncomeExpenseReportBloc>().add(
                  LoadIncomeExpenseReport(
                    periodType: p,
                    compareToPrevious: _showComparison,
                  ),
                );
              },
              icon: Icon(
                Icons.calendar_view_month_outlined,
                color: kit.colors.textPrimary,
              ),
              tooltip: AppLocalizations.of(context)!.changePeriodAggregation,
              itemBuilder: (_) => IncomeExpensePeriodType.values
                  .map(
                    (p) => PopupMenuItem<IncomeExpensePeriodType>(
                      value: p,
                      child: AppText(
                        toBeginningOfSentenceCase(p.name) ?? p.name,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
      onExportCSV: () async {
        final state = context.read<IncomeExpenseReportBloc>().state;
        if (state is IncomeExpenseReportLoaded) {
          final helper = sl<CsvExportHelper>();
          final result = await helper.exportIncomeExpenseReport(
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
      body: BlocBuilder<IncomeExpenseReportBloc, IncomeExpenseReportState>(
        builder: (context, state) {
          if (state is IncomeExpenseReportLoading)
            return const Center(child: AppLoadingIndicator());
          if (state is IncomeExpenseReportError)
            return Center(
              child: AppText(
                "Error: ${state.message}",
                color: kit.colors.error,
              ),
            );
          if (state is IncomeExpenseReportLoaded) {
            final reportData = state.reportData;
            if (reportData.periodData.isEmpty)
              return const Center(
                child: AppText("No income or expense data for this period."),
              );

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
                  context,
                  reportData.periodData[groupIndex],
                  type,
                );
              },
            );

            return ListView(
              children: [
                Padding(
                  padding: kit.spacing.vMd.add(kit.spacing.hSm),
                  child: AspectRatio(aspectRatio: 16 / 9, child: chartWidget),
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
          return const Center(child: AppText("Select filters to view report."));
        },
      ),
    );
  }

  String _formatPeriodHeader(
    DateTime date,
    IncomeExpensePeriodType periodType,
  ) {
    switch (periodType) {
      case IncomeExpensePeriodType.monthly:
        return DateFormat('MMM yyyy').format(date);
      case IncomeExpensePeriodType.yearly:
        return DateFormat('yyyy').format(date);
    }
  }

  Widget _buildDataTable(
    BuildContext context,
    IncomeExpenseReportData data,
    SettingsState settings,
    bool showComparison,
  ) {
    final kit = context.kit;
    final currencySymbol = settings.currencySymbol;

    List<DataColumn> columns = [
      DataColumn(label: AppText('Period', style: AppTextStyle.bodyStrong)),
      DataColumn(
        label: AppText('Income', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
      DataColumn(
        label: AppText('Expense', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
      DataColumn(
        label: AppText('Net Flow', style: AppTextStyle.bodyStrong),
        numeric: true,
      ),
    ];
    if (showComparison) {
      columns.addAll([
        DataColumn(
          label: AppText('Prev Net', style: AppTextStyle.bodyStrong),
          numeric: true,
        ),
        DataColumn(
          label: AppText('Net Δ%', style: AppTextStyle.bodyStrong),
          numeric: true,
        ),
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
              : kit.colors.error;
          double? changePercent = netFlow.percentageChange;
          Color changeColor = kit.colors.textMuted;
          String changeText = "N/A";

          if (showComparison && changePercent != null) {
            if (changePercent.isInfinite) {
              changeText = changePercent.isNegative ? '-∞' : '+∞';
              changeColor = changePercent.isNegative
                  ? kit.colors.error
                  : Colors.green.shade700; // Negative change is worsening
            } else if (!changePercent.isNaN) {
              changeText =
                  '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%';
              changeColor = changePercent >= 0
                  ? Colors.green.shade700
                  : kit.colors.error; // Positive change is improving
            }
          }

          return DataRow(
            cells: [
              DataCell(
                AppText(_formatPeriodHeader(item.periodStart, data.periodType)),
              ),
              DataCell(
                AppText(
                  CurrencyFormatter.format(
                    item.currentTotalIncome,
                    currencySymbol,
                  ),
                ),
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  _navigateToFilteredTransactions(
                    context,
                    item,
                    TransactionType.income,
                  );
                },
              ),
              DataCell(
                AppText(
                  CurrencyFormatter.format(
                    item.currentTotalExpense,
                    currencySymbol,
                  ),
                ),
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  _navigateToFilteredTransactions(
                    context,
                    item,
                    TransactionType.expense,
                  );
                },
              ),
              DataCell(
                AppText(
                  CurrencyFormatter.format(item.currentNetFlow, currencySymbol),
                  style: AppTextStyle.bodyStrong,
                  color: netFlowColor,
                ),
              ),
              if (showComparison)
                DataCell(
                  AppText(
                    netFlow.previousValue != null
                        ? CurrencyFormatter.format(
                            netFlow.previousValue!,
                            currencySymbol,
                          )
                        : 'N/A',
                  ),
                ),
              if (showComparison)
                DataCell(AppText(changeText, color: changeColor)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
