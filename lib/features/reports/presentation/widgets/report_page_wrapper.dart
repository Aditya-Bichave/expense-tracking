// lib/features/reports/presentation/widgets/report_page_wrapper.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart'; // Import helper
import 'package:expense_tracker/features/reports/presentation/widgets/report_filter_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart'; // Import filter bloc
import 'package:expense_tracker/main.dart'; // Logger

class ReportPageWrapper extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  // --- ADDED: Callback to get data for export ---
  final Future<Either<String, Failure>> Function()?
      onExportCSV; // Returns CSV string or Failure
  // final Future<Either<Uint8List, Failure>> Function()? onExportPDF; // For PDF later
  // --- END ADD ---

  const ReportPageWrapper({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onExportCSV, // Make optional
    // this.onExportPDF,
  });

  // --- ADDED: Export Action Handling ---
  Future<void> _handleExportCSV(BuildContext context) async {
    if (onExportCSV == null) return;

    log.info("[ReportWrapper] CSV Export requested for report: $title");
    // Show loading indicator maybe?
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Generating CSV...")));

    final result = await onExportCSV!();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(); // Hide generating message

    result.fold((csvData) async {
      log.info("[ReportWrapper] CSV data generated. Triggering download/save.");
      try {
        final exportHelper = sl<CsvExportHelper>(); // Get helper instance
        final fileName =
            '${title.toLowerCase().replaceAll(' ', '_')}_export_${DateTime.now().toIso8601String().split('T').first}.csv';
        await exportHelper.saveCsvFile(context, csvData, fileName);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("CSV export successful!"),
            backgroundColor: Colors.green));
      } catch (e) {
        log.severe("[ReportWrapper] Error saving CSV file: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error saving CSV: $e"),
            backgroundColor: Colors.red));
      }
    }, (failure) {
      log.warning(
          "[ReportWrapper] Failed to generate CSV data: ${failure.message}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("CSV Export Failed: ${failure.message}"),
          backgroundColor: Colors.red));
    });
  }
  // --- END Export Handling ---

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Filter Button
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: "Filters",
            onPressed: () => ReportFilterControls.showFilterSheet(context),
          ),
          // Report Specific Actions
          if (actions != null) ...actions!,
          // Export Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            tooltip: "Export Report",
            onSelected: (String result) {
              if (result == 'csv') {
                _handleExportCSV(context);
              } else if (result == 'pdf') {
                // _handleExportPDF(context); // Call PDF handler later
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("PDF Export (Coming Soon)")));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (onExportCSV != null) // Only show if callback is provided
                const PopupMenuItem<String>(
                  value: 'csv',
                  child: ListTile(
                      leading: Icon(Icons.description_outlined),
                      title: Text('Export as CSV')),
                ),
              // Add PDF option later
              const PopupMenuItem<String>(
                value: 'pdf',
                enabled: false, // Disable for now
                child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('Export as PDF (Soon)')),
              ),
            ],
          ),
        ],
      ),
      body: body,
    );
  }
}

// --- Failure Class (Ensure these exist in core/error/failure.dart) ---
// class ExportFailure extends Failure {
//   const ExportFailure(String message) : super(message);
// }
// class FileSystemFailure extends Failure {
//   const FileSystemFailure(String message) : super(message);
// }
