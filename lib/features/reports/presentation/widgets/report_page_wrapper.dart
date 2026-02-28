import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart'; // Import helper
import 'package:expense_tracker/features/reports/presentation/widgets/report_filter_controls.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/main.dart'; // Logger
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';

class ReportPageWrapper extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  // Adjusted type to match what CsvExportHelper likely returns (Left=Failure, Right=String)
  // If CsvExportHelper returns Left=String, Right=Failure (Anti-pattern), we need to check that.
  // Assuming standard Either<Failure, String>.
  final Future<Either<Failure, String>> Function()? onExportCSV;

  const ReportPageWrapper({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onExportCSV,
  });

  Future<void> _handleExportCSV(BuildContext context) async {
    if (onExportCSV == null) return;
    final kit = context.kit;

    log.info("[ReportWrapper] CSV Export requested for report: $title");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText("Generating CSV...", color: kit.colors.onPrimary),
        backgroundColor: kit.colors.primary,
      ),
    );

    final result = await onExportCSV!();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    result.fold(
      (failure) {
        log.warning(
          "[ReportWrapper] Failed to generate CSV data: ${failure.message}",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              "CSV Export Failed: ${failure.message}",
              color: kit.colors.onError,
            ),
            backgroundColor: kit.colors.error,
          ),
        );
      },
      (csvData) async {
        log.info(
          "[ReportWrapper] CSV data generated. Triggering download/save.",
        );
        try {
          final exportHelper = sl<CsvExportHelper>();
          final fileName =
              '${title.toLowerCase().replaceAll(' ', '_')}_export_${DateTime.now().toIso8601String().split('T').first}.csv';
          await exportHelper.saveCsvFile(
            context: context,
            csvData: csvData,
            fileName: fileName,
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                "CSV export successful!",
                color: kit.colors.onPrimary,
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
        } catch (e) {
          log.severe("[ReportWrapper] Error saving CSV file: $e");
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                "Error saving CSV: $e",
                color: kit.colors.onError,
              ),
              backgroundColor: kit.colors.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppScaffold(
      appBar: AppNavBar(
        title: title,
        actions: [
          // Filter Button
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: kit.colors.textPrimary,
            ),
            tooltip: "Filters",
            onPressed: () => ReportFilterControls.showFilterSheet(context),
          ),
          // Report Specific Actions
          if (actions != null) ...actions!,
          // Export Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.download_outlined, color: kit.colors.textPrimary),
            tooltip: "Export Report",
            color: kit.colors.surfaceContainer,
            onSelected: (String result) {
              if (result == 'csv') {
                _handleExportCSV(context);
              } else if (result == 'pdf') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText(
                      "PDF Export (Coming Soon)",
                      color: kit.colors.onPrimary,
                    ),
                    backgroundColor: kit.colors.primary,
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (onExportCSV != null)
                PopupMenuItem<String>(
                  value: 'csv',
                  child: ListTile(
                    leading: Icon(
                      Icons.description_outlined,
                      color: kit.colors.textSecondary,
                    ),
                    title: Text('Export as CSV', style: kit.typography.body),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem<String>(
                value: 'pdf',
                enabled: false,
                child: ListTile(
                  // Use textSecondary or textPrimary with opacity since textDisabled doesn't exist
                  leading: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: kit.colors.textSecondary.withOpacity(0.5),
                  ),
                  title: Text(
                    'Export as PDF (Soon)',
                    style: kit.typography.body.copyWith(
                      color: kit.colors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: body,
    );
  }
}
