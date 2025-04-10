// lib/features/reports/domain/helpers/csv_export_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class CsvExportHelper {
  /// Generates CSV from a list of maps.
  Future<String> _generateCsv(
      List<List<dynamic>> dataRows, List<String> headers) async {
    try {
      List<List<dynamic>> csvData = [headers]; // Start with headers
      csvData.addAll(dataRows);
      String csv = const ListToCsvConverter().convert(csvData);
      return csv;
    } catch (e, s) {
      log.severe("Error generating CSV string: $e\n$s");
      throw Exception("CSV Generation Error: $e");
    }
  }

  /// Saves the CSV file using appropriate platform method.
  Future<void> saveCsvFile(
      BuildContext context, String csvData, String fileName) async {
    if (kIsWeb) {
      _saveCsvWeb(csvData, fileName);
    } else {
      await _saveCsvMobileDesktop(context, csvData, fileName);
    }
  }

  /// Web implementation using dart:html
  void _saveCsvWeb(String csvData, String fileName) {
    try {
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      log.info("[CsvExportHelper] Web CSV download initiated for '$fileName'.");
    } catch (e, s) {
      log.severe("[CsvExportHelper] Error saving CSV on Web: $e\n$s");
      throw Exception("Web Download Error: $e");
    }
  }

  /// Mobile/Desktop implementation using file_picker and path_provider
  Future<void> _saveCsvMobileDesktop(
      BuildContext context, String csvData, String fileName) async {
    try {
      // Request storage permission (especially needed for Android < 10 and sometimes iOS)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        var status = await Permission.storage.status;
        // On Android 13+ manage external storage might be needed depending on path
        // Consider using Permission.manageExternalStorage or scoped storage approaches
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        if (!status.isGranted) {
          log.warning("[CsvExportHelper] Storage permission denied.");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Storage permission required to save file.")));
          throw Exception("Storage permission denied.");
        }
      }

      // Get a directory using file_picker's saveFile dialog
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: fileName,
        allowedExtensions: ['csv'],
        lockParentWindow: true, // Good practice for desktop
      );

      if (outputFile == null) {
        log.info("[CsvExportHelper] User cancelled CSV save.");
        throw Exception(
            "Save cancelled by user."); // Throw to indicate cancellation
      }

      String finalPath = outputFile;
      if (!finalPath.toLowerCase().endsWith('.csv')) {
        finalPath += '.csv';
      }

      log.info("[CsvExportHelper] Saving CSV to path: $finalPath");
      final file = File(finalPath);
      await file.writeAsString(csvData, flush: true);
      log.info("[CsvExportHelper] CSV file saved successfully.");

      // Optionally show a success message or open the file location
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("CSV saved to $finalPath"),
          action: SnackBarAction(label: "OK", onPressed: () {})));
    } on PlatformException catch (e, s) {
      log.severe("[CsvExportHelper] PlatformException saving CSV: $e\n$s");
      throw Exception("File Picker Error: ${e.message}");
    } catch (e, s) {
      log.severe("[CsvExportHelper] Error saving CSV file: $e\n$s");
      throw Exception("File Save Error: $e");
    }
  }

  // --- Specific Export Methods for Each Report Type ---

  Future<Either<String, Failure>> exportSpendingCategoryReport(
      SpendingCategoryReportData data, String currencySymbol) async {
    try {
      final headers = ['Category', 'Amount ($currencySymbol)', 'Percentage'];
      final rows = data.spendingByCategory
          .map((item) => [
                item.categoryName,
                item.totalAmount
                    .toStringAsFixed(2), // Ensure consistent decimal places
                '${(item.percentage * 100).toStringAsFixed(1)}%',
              ])
          .toList();
      // Add total row
      rows.add(['TOTAL', data.totalSpending.toStringAsFixed(2), '100.0%']);

      final csvString = await _generateCsv(rows, headers);
      return Left(csvString);
    } catch (e) {
      return Right(
          ExportFailure("Failed to generate Category Spending CSV: $e"));
    }
  }

  Future<Either<String, Failure>> exportSpendingTimeReport(
      SpendingTimeReportData data, String currencySymbol) async {
    try {
      final headers = ['Period Start', 'Amount ($currencySymbol)'];
      final DateFormat dateFormat =
          data.granularity == TimeSeriesGranularity.daily
              ? DateFormat('yyyy-MM-dd')
              : data.granularity == TimeSeriesGranularity.weekly
                  ? DateFormat('yyyy-MM-dd \'Wk\'') // Indicate week start
                  : DateFormat('yyyy-MMM');

      final rows = data.spendingData
          .map((item) => [
                dateFormat.format(item.date),
                item.amount.toStringAsFixed(2),
              ])
          .toList();

      final csvString = await _generateCsv(rows, headers);
      return Left(csvString);
    } catch (e) {
      return Right(
          ExportFailure("Failed to generate Spending Over Time CSV: $e"));
    }
  }

  Future<Either<String, Failure>> exportIncomeExpenseReport(
      IncomeExpenseReportData data, String currencySymbol) async {
    try {
      final headers = [
        'Period Start',
        'Income ($currencySymbol)',
        'Expense ($currencySymbol)',
        'Net Flow ($currencySymbol)'
      ];
      final DateFormat dateFormat =
          data.periodType == IncomeExpensePeriodType.monthly
              ? DateFormat('yyyy-MMM')
              : DateFormat('yyyy');

      final rows = data.periodData
          .map((item) => [
                dateFormat.format(item.periodStart),
                item.totalIncome.toStringAsFixed(2),
                item.totalExpense.toStringAsFixed(2),
                item.netFlow.toStringAsFixed(2),
              ])
          .toList();

      final csvString = await _generateCsv(rows, headers);
      return Left(csvString);
    } catch (e) {
      return Right(
          ExportFailure("Failed to generate Income vs Expense CSV: $e"));
    }
  }

  Future<Either<String, Failure>> exportBudgetPerformanceReport(
      BudgetPerformanceReportData data, String currencySymbol) async {
    try {
      final headers = [
        'Budget',
        'Target ($currencySymbol)',
        'Actual ($currencySymbol)',
        'Variance ($currencySymbol)',
        'Variance (%)'
      ];
      final rows = data.performanceData
          .map((item) => [
                item.budget.name,
                item.budget.targetAmount.toStringAsFixed(2),
                item.actualSpending.toStringAsFixed(2),
                item.varianceAmount.toStringAsFixed(2),
                item.variancePercent.isFinite
                    ? '${item.variancePercent.toStringAsFixed(1)}%'
                    : (item.variancePercent.isNegative ? '-Inf' : '+Inf'),
              ])
          .toList();
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
        'Status'
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
              ? DateFormatter.formatDate(goal.targetDate!)
              : 'N/A',
          goal.status.displayName,
        ];
      }).toList();
      // Optionally add contributions details here or in a separate export
      final csvString = await _generateCsv(rows, headers);
      return Left(csvString);
    } catch (e) {
      return Right(ExportFailure("Failed to generate Goal Progress CSV: $e"));
    }
  }
}

// Define ExportFailure if it doesn't exist
class ExportFailure extends Failure {
  const ExportFailure(String message) : super(message);
}
