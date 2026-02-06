import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:expense_tracker/core/services/downloader_service.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart' as df;
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';

class CsvExportHelper {
  final DownloaderService _downloaderService;

  CsvExportHelper({required DownloaderService downloaderService})
      : _downloaderService = downloaderService;

  Future<String> _generateCsv(
      List<List<dynamic>> dataRows, List<String> headers) async {
    try {
      List<List<dynamic>> csvData = [headers];
      csvData.addAll(dataRows);
      String csv = const ListToCsvConverter().convert(csvData);
      return csv;
    } catch (e, s) {
      log.severe("Error generating CSV string: $e\n$s");
      throw Exception("CSV Generation Error: $e");
    }
  }

  Future<void> saveCsvFile(
      {required BuildContext context,
      required String csvData,
      required String fileName}) async {
    if (kIsWeb) {
      await _saveCsvWeb(csvData, fileName);
    } else {
      await _saveCsvMobileDesktop(context, csvData, fileName);
    }
  }

  Future<void> _saveCsvWeb(String csvData, String fileName) async {
    try {
      final bytes = utf8.encode(csvData);
      await _downloaderService.downloadFile(
        bytes: Uint8List.fromList(bytes),
        downloadName: fileName,
        mimeType: 'text/csv;charset=utf-8;',
      );
      log.info("[CsvExportHelper] Web CSV download initiated for '$fileName'.");
    } catch (e, s) {
      log.severe("[CsvExportHelper] Error saving CSV on Web: $e\n$s");
      throw Exception("Web Download Error: $e");
    }
  }

  Future<void> _saveCsvMobileDesktop(
      BuildContext context, String csvData, String fileName) async {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvData, flush: true);
      await Share.shareXFiles([XFile(file.path)], text: fileName);
      return;
    }

    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: fileName,
        allowedExtensions: ['csv'],
        type: FileType.custom,
        lockParentWindow: true,
      );

      if (outputFile == null) {
        log.info("[CsvExportHelper] User cancelled CSV save.");
        throw Exception("Save cancelled by user.");
      }

      String finalPath = outputFile;
      if (!finalPath.toLowerCase().endsWith('.csv')) {
        finalPath += '.csv';
      }

      log.info("[CsvExportHelper] Saving CSV to path: $finalPath");
      final file = File(finalPath);
      await file.writeAsString(csvData, flush: true);
      log.info("[CsvExportHelper] CSV file saved successfully.");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("CSV saved to ${file.parent.path}"),
            action: SnackBarAction(label: "OK", onPressed: () {})));
      }
    } on PlatformException catch (e, s) {
      log.severe("[CsvExportHelper] PlatformException saving CSV: $e\n$s");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("File Picker Error: ${e.message ?? 'Unknown'}")));
      }
      throw Exception("File Picker Error: ${e.message}");
    } catch (e, s) {
      log.severe("[CsvExportHelper] Error saving CSV file: $e\n$s");
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("File Save Error: $e")));
      }
      throw Exception("File Save Error: $e");
    }
  }

  Future<Either<String, Failure>> exportSpendingCategoryReport(
      SpendingCategoryReportData data, String currencySymbol,
      {bool showComparison = false}) async {
    try {
      List<String> headers = [
        'Category',
        'Amount ($currencySymbol)',
        'Percentage'
      ];
      if (showComparison) {
        headers.addAll(['Previous Amount ($currencySymbol)', 'Change (%)']);
      }

      final rows = data.spendingByCategory.map((item) {
        List<dynamic> rowData = [
          item.categoryName,
          item.currentTotalAmount.toStringAsFixed(2),
          '${(item.percentage * 100).toStringAsFixed(1)}%'
        ];
        if (showComparison) {
          rowData
              .add(item.totalAmount.previousValue?.toStringAsFixed(2) ?? 'N/A');
          rowData
              .add(_formatPercentageChange(item.totalAmount.percentageChange));
        }
        return rowData;
      }).toList();

      List<dynamic> totalRow = [
        'TOTAL',
        data.currentTotalSpending.toStringAsFixed(2),
        '100.0%'
      ];
      if (showComparison) {
        totalRow
            .add(data.totalSpending.previousValue?.toStringAsFixed(2) ?? 'N/A');
        totalRow
            .add(_formatPercentageChange(data.totalSpending.percentageChange));
      }
      rows.add(totalRow);

      final csvString = await _generateCsv(rows, headers);
      return Left(csvString);
    } catch (e) {
      return Right(
          ExportFailure("Failed to generate Category Spending CSV: $e"));
    }
  }

  Future<Either<String, Failure>> exportSpendingTimeReport(
      SpendingTimeReportData data, String currencySymbol,
      {bool showComparison = false}) async {
    try {
      List<String> headers = ['Period Start', 'Amount ($currencySymbol)'];
      if (showComparison) {
        headers.addAll(['Previous Amount ($currencySymbol)', 'Change (%)']);
      }

      final DateFormat dateFormat =
          data.granularity == TimeSeriesGranularity.daily
              ? DateFormat('yyyy-MM-dd')
              : data.granularity == TimeSeriesGranularity.weekly
                  ? DateFormat('yyyy-MM-dd \'Wk\'')
                  : DateFormat('yyyy-MMM');

      final rows = data.spendingData.map((item) {
        List<dynamic> rowData = [
          dateFormat.format(item.date),
          item.currentAmount.toStringAsFixed(2)
        ];
        if (showComparison) {
          rowData.add(item.amount.previousValue?.toStringAsFixed(2) ?? 'N/A');
          rowData.add(_formatPercentageChange(item.amount.percentageChange));
        }
        return rowData;
      }).toList();

      final csvString = await _generateCsv(rows, headers);
      return Left(csvString);
    } catch (e) {
      return Right(
          ExportFailure("Failed to generate Spending Over Time CSV: $e"));
    }
  }

  Future<Either<String, Failure>> exportIncomeExpenseReport(
      IncomeExpenseReportData data, String currencySymbol,
      {bool showComparison = false}) async {
    try {
      List<String> headers = [
        'Period Start',
        'Income ($currencySymbol)',
        'Expense ($currencySymbol)',
        'Net Flow ($currencySymbol)'
      ];
      if (showComparison) {
        headers.addAll([
          'Prev Income ($currencySymbol)',
          'Prev Expense ($currencySymbol)',
          'Prev Net Flow ($currencySymbol)',
          'Net Change (%)'
        ]);
      }

      final DateFormat dateFormat =
          data.periodType == IncomeExpensePeriodType.monthly
              ? DateFormat('yyyy-MMM')
              : DateFormat('yyyy');

      final rows = data.periodData.map((item) {
        List<dynamic> rowData = [
          dateFormat.format(item.periodStart),
          item.currentTotalIncome.toStringAsFixed(2),
          item.currentTotalExpense.toStringAsFixed(2),
          item.currentNetFlow.toStringAsFixed(2)
        ];
        if (showComparison) {
          rowData
              .add(item.totalIncome.previousValue?.toStringAsFixed(2) ?? 'N/A');
          rowData.add(
              item.totalExpense.previousValue?.toStringAsFixed(2) ?? 'N/A');
          rowData.add(item.netFlow.previousValue?.toStringAsFixed(2) ?? 'N/A');
          rowData.add(_formatPercentageChange(item.netFlow.percentageChange));
        }
        return rowData;
      }).toList();

      final csvString = await _generateCsv(rows, headers);
      return Left(csvString);
    } catch (e) {
      return Right(
          ExportFailure("Failed to generate Income vs Expense CSV: $e"));
    }
  }

  Future<Either<String, Failure>> exportBudgetPerformanceReport(
      BudgetPerformanceReportData data, String currencySymbol,
      {bool showComparison = false}) async {
    try {
      List<String> headers = [
        'Budget',
        'Target ($currencySymbol)',
        'Actual ($currencySymbol)',
        'Variance ($currencySymbol)',
        'Variance (%)'
      ];
      bool canCompare = showComparison &&
          data.previousPerformanceData != null &&
          data.previousPerformanceData!.isNotEmpty;
      if (canCompare) {
        headers.addAll([
          'Prev Actual ($currencySymbol)',
          'Prev Variance ($currencySymbol)',
          'Prev Variance (%)',
          'Var Δ%'
        ]);
      }

      final rows = data.performanceData.map((item) {
        List<dynamic> rowData = [
          item.budget.name,
          item.budget.targetAmount.toStringAsFixed(2),
          item.currentActualSpending.toStringAsFixed(2),
          item.currentVarianceAmount.toStringAsFixed(2),
          item.currentVariancePercent.isFinite
              ? '${item.currentVariancePercent.toStringAsFixed(1)}%'
              : (item.currentVariancePercent.isNegative ? '-Inf' : '+Inf'),
        ];
        if (canCompare) {
          final prevData = data.previousPerformanceData!
              .firstWhereOrNull((p) => p.budget.id == item.budget.id);
          rowData
              .add(prevData?.currentActualSpending.toStringAsFixed(2) ?? 'N/A');
          rowData
              .add(prevData?.currentVarianceAmount.toStringAsFixed(2) ?? 'N/A');
          rowData.add(item.previousVariancePercent?.isFinite == true
              ? '${item.previousVariancePercent!.toStringAsFixed(1)}%'
              : 'N/A');
          rowData.add(_formatPercentageChange(item.varianceChangePercent));
        }
        return rowData;
      }).toList();

      final csvString = await _generateCsv(rows, headers);
      return Left(csvString);
    } catch (e) {
      return Right(
          ExportFailure("Failed to generate Budget Performance CSV: $e"));
    }
  }

  Future<Either<String, Failure>> exportGoalProgressReport(
      GoalProgressReportData data, String currencySymbol) async {
    try {
      final headers = [
        'Goal',
        'Target ($currencySymbol)',
        'Saved ($currencySymbol)',
        'Remaining ($currencySymbol)',
        'Progress (%)',
        'Target Date',
        'Status',
        'Est. Daily Save',
        'Est. Monthly Save',
        'Est. Completion'
      ];
      final rows = data.progressData.map((item) {
        final goal = item.goal;
        return [
          goal.name,
          goal.targetAmount.toStringAsFixed(2),
          goal.totalSaved.toStringAsFixed(2),
          goal.amountRemaining.toStringAsFixed(2),
          (goal.percentageComplete * 100).toStringAsFixed(1),
          goal.targetDate != null
              ? df.DateFormatter.formatDate(goal.targetDate!)
              : 'N/A',
          goal.status.displayName,
          item.requiredDailySaving?.isFinite == true
              ? CurrencyFormatter.format(
                  item.requiredDailySaving!, currencySymbol)
              : 'N/A',
          item.requiredMonthlySaving?.isFinite == true
              ? CurrencyFormatter.format(
                  item.requiredMonthlySaving!, currencySymbol)
              : 'N/A',
          item.estimatedCompletionDate != null
              ? df.DateFormatter.formatDate(item.estimatedCompletionDate!)
              : 'N/A',
        ];
      }).toList();
      final csvString = await _generateCsv(rows, headers);
      return Left(csvString);
    } catch (e) {
      return Right(ExportFailure("Failed to generate Goal Progress CSV: $e"));
    }
  }

  String _formatPercentageChange(double? percentageChange) {
    if (percentageChange == null) return 'N/A';
    if (percentageChange.isInfinite) {
      return percentageChange.isNegative ? '-∞' : '+∞';
    }
    if (percentageChange.isNaN) return 'N/A';
    return '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%';
  }
}

class ExportFailure extends Failure {
  const ExportFailure(String message) : super(message);
}
