// features/settings/domain/usecases/backup_data_usecase.dart

import 'dart:convert';
import 'dart:io'; // dart:io is needed for File on non-web
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart'; // Import kIsWeb

// --- Conditional imports for web download ---
import 'dart:typed_data'; // For Uint8List
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Use prefix 'html'
// -----------------------------------------

class BackupFailure extends Failure {
  const BackupFailure(String message) : super(message);
}

class BackupDataUseCase implements UseCase<String?, NoParams> {
  final DataManagementRepository dataManagementRepository;

  BackupDataUseCase(this.dataManagementRepository);

  @override
  Future<Either<Failure, String?>> call(NoParams params) async {
    debugPrint(
        "[BackupUseCase] Backup process started. Platform: ${kIsWeb ? 'Web' : 'Non-Web'}");
    try {
      // 1. Get data
      debugPrint("[BackupUseCase] Fetching all data...");
      final dataEither = await dataManagementRepository.getAllDataForBackup();
      if (dataEither.isLeft()) {
        return dataEither.fold((failure) => Left(failure),
            (_) => const Left(BackupFailure("Failed to retrieve data.")));
      }
      final allData =
          dataEither.getOrElse(() => throw Exception("Data retrieval error"));
      debugPrint("[BackupUseCase] Data fetched.");

      // 2. Get App Version Info
      debugPrint("[BackupUseCase] Fetching package info...");
      String appVersion = 'unknown';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (e) {
        debugPrint("[BackupUseCase] Warning: Could not get package info: $e");
      }
      debugPrint("[BackupUseCase] App version: $appVersion");

      // 3. Prepare backup structure
      final backupTimestamp = DateTime.now().toIso8601String();
      final backupData = {
        'metadata': {
          'appVersion': appVersion,
          'backupTimestamp': backupTimestamp,
          'formatVersion': '1.0',
        },
        'data': allData.toJson(),
      };
      debugPrint("[BackupUseCase] Backup structure prepared.");

      // 4. Prepare file content (JSON String)
      debugPrint("[BackupUseCase] Encoding data to JSON...");
      final jsonString = jsonEncode(backupData);
      final backupFilename =
          'expense_tracker_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      // --- Platform Specific Logic ---
      if (kIsWeb) {
        // --- Web: Trigger Download ---
        debugPrint("[BackupUseCase] Platform is Web. Triggering download...");
        try {
          final bytes = utf8.encode(jsonString); // Convert String to bytes
          final blob = html.Blob([bytes], 'application/json'); // Create blob
          final url =
              html.Url.createObjectUrlFromBlob(blob); // Create object URL
          final anchor = html.document.createElement('a')
              as html.AnchorElement // Create anchor tag
            ..href = url
            ..style.display = 'none'
            ..download = backupFilename; // Set filename for download
          html.document.body!.children.add(anchor); // Add to body
          anchor.click(); // Simulate click to trigger download
          html.document.body!.children.remove(anchor); // Remove anchor
          html.Url.revokeObjectUrl(url); // Release object URL
          debugPrint(
              "[BackupUseCase] Web download initiated for '$backupFilename'.");
          // For web, we can't easily return the actual path, so return success message
          return const Right('Download started');
        } catch (e, s) {
          debugPrint("[BackupUseCase] Error during web download: $e\n$s");
          return Left(
              BackupFailure("Failed to initiate download: ${e.toString()}"));
        }
        // --- End Web Logic ---
      } else {
        // --- Non-Web: Use saveFile ---
        debugPrint(
            "[BackupUseCase] Platform is Non-Web. Prompting user for save file location...");
        try {
          final String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Expense Backup',
            fileName: backupFilename,
            // type: FileType.custom, // Not strictly needed if filtering by extension
            // allowedExtensions: ['json'], // Filter extensions
          );

          if (outputFile == null) {
            debugPrint("[BackupUseCase] User cancelled file picker.");
            return const Left(BackupFailure("Backup cancelled by user."));
          }
          debugPrint("[BackupUseCase] User selected path: $outputFile");

          // Ensure the path has the correct extension (saveFile might not enforce it on all platforms)
          String finalPath = outputFile;
          if (!finalPath.toLowerCase().endsWith('.json')) {
            finalPath += '.json';
          }

          // Write file using dart:io
          debugPrint("[BackupUseCase] Writing JSON to file: $finalPath...");
          final file = File(finalPath);
          await file.writeAsString(jsonString);
          debugPrint("[BackupUseCase] File written successfully.");
          return Right(finalPath); // Return actual path
        } on UnimplementedError {
          // This should ideally not happen now due to kIsWeb check, but good failsafe
          debugPrint(
              "[BackupUseCase] Error: saveFile called on unsupported platform (should be web?).");
          return const Left(BackupFailure(
              "Save file dialog not supported on this platform."));
        } on FileSystemException catch (e) {
          debugPrint("[BackupUseCase] FileSystemException: $e");
          return Left(BackupFailure("File system error: ${e.message}"));
        } catch (e, s) {
          debugPrint("[BackupUseCase] Error writing file: $e\n$s");
          return Left(
              BackupFailure("Failed to write backup file: ${e.toString()}"));
        }
        // --- End Non-Web Logic ---
      }
      // --- End Platform Specific Logic ---
    } catch (e, s) {
      debugPrint("[BackupUseCase] Unexpected error: $e\n$s");
      return Left(BackupFailure(
          "An unexpected error occurred during backup: ${e.toString()}"));
    }
  }
}
