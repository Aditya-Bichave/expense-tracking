// lib/features/settings/domain/usecases/backup_data_usecase.dart

import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/services.dart';

// Conditional imports for web download
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Import constants
import 'package:expense_tracker/core/constants/app_constants.dart';

class BackupDataUseCase implements UseCase<String?, NoParams> {
  final DataManagementRepository dataManagementRepository;

  BackupDataUseCase(this.dataManagementRepository);

  @override
  Future<Either<Failure, String?>> call(NoParams params) async {
    log.info(
        "[BackupUseCase] Backup process started. Platform: ${kIsWeb ? 'Web' : 'Non-Web'}");
    try {
      // 1. Get data
      log.info("[BackupUseCase] Fetching all data...");
      final dataEither = await dataManagementRepository.getAllDataForBackup();
      if (dataEither.isLeft()) {
        log.warning("[BackupUseCase] Failed to retrieve data for backup.");
        return dataEither.fold((failure) => Left(failure),
            (_) => const Left(BackupFailure("Failed to retrieve data.")));
      }
      final allData =
          dataEither.getOrElse(() => throw Exception("Data retrieval error"));
      log.info("[BackupUseCase] Data fetched.");

      // 2. Get App Version Info
      log.info("[BackupUseCase] Fetching package info...");
      String appVersion = 'unknown';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (e) {
        log.warning("[BackupUseCase] Could not get package info: $e");
      }
      log.info("[BackupUseCase] App version: $appVersion");

      // 3. Prepare backup structure using constants
      final backupTimestamp = DateTime.now().toUtc().toIso8601String();
      final backupData = {
        AppConstants.backupMetaKey: {
          AppConstants.backupVersionKey: appVersion,
          AppConstants.backupTimestampKey: backupTimestamp,
          AppConstants.backupFormatVersionKey: AppConstants.backupFormatVersion,
        },
        AppConstants.backupDataKey:
            allData.toJson(), // Uses keys from AllData.toJson
      };
      log.info("[BackupUseCase] Backup structure prepared.");

      // 4. Prepare file content (JSON String)
      log.info("[BackupUseCase] Encoding data to JSON...");
      final jsonString = jsonEncode(backupData);
      final backupFilename =
          '${AppConstants.appName.toLowerCase().replaceAll(' ', '_')}_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json'; // Use app name constant

      // --- Platform Specific Logic ---
      if (kIsWeb) {
        // --- Web: Trigger Download ---
        log.info("[BackupUseCase] Platform is Web. Triggering download...");
        try {
          final bytes = utf8.encode(jsonString);
          final blob = html.Blob([bytes], 'application/json');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = backupFilename;
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
          log.info(
              "[BackupUseCase] Web download initiated for '$backupFilename'.");
          return const Right('Download started');
        } catch (e, s) {
          log.severe("[BackupUseCase] Error during web download$e$s");
          return Left(
              BackupFailure("Failed to initiate download: ${e.toString()}"));
        }
      } else {
        // --- Non-Web: Use saveFile ---
        log.info(
            "[BackupUseCase] Platform is Non-Web. Prompting user for save file location...");
        try {
          final String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup File',
            fileName: backupFilename,
            allowedExtensions: ['json'],
          );

          if (outputFile == null) {
            log.info("[BackupUseCase] User cancelled file picker.");
            return const Left(BackupFailure("Backup cancelled by user."));
          }
          log.info("[BackupUseCase] User selected path: $outputFile");

          String finalPath = outputFile;
          if (!finalPath.toLowerCase().endsWith('.json')) {
            finalPath += '.json';
            log.info("[BackupUseCase] Appended .json extension: $finalPath");
          }

          log.info("[BackupUseCase] Writing JSON to file: $finalPath...");
          final file = File(finalPath);
          await file.writeAsString(jsonString, flush: true);
          log.info("[BackupUseCase] File written successfully.");
          return Right(finalPath);
        } on PlatformException catch (e, s) {
          log.severe("[BackupUseCase] PlatformException during saveFile$e$s");
          return Left(
              BackupFailure("Could not save file: ${e.message} (${e.code})"));
        } on FileSystemException catch (e, s) {
          log.severe("[BackupUseCase] FileSystemException writing file$e$s");
          return Left(FileSystemFailure("File system error: ${e.message}"));
        } catch (e, s) {
          log.severe("[BackupUseCase] Unexpected error writing file$e$s");
          return Left(
              BackupFailure("Failed to write backup file: ${e.toString()}"));
        }
      }
    } catch (e, s) {
      log.severe("[BackupUseCase] Unexpected error in backup process$e$s");
      return Left(BackupFailure(
          "An unexpected error occurred during backup: ${e.toString()}"));
    }
  }
}
