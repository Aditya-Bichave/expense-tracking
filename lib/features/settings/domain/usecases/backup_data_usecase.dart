import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/downloader_service.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/core/utils/encryption_helper.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/core/services/file_picker_service.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/services.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class BackupDataUseCase implements UseCase<String?, BackupParams> {
  final DataManagementRepository dataManagementRepository;
  final DownloaderService downloaderService;
  final FilePickerService _filePickerService;

  BackupDataUseCase({
    required this.dataManagementRepository,
    required this.downloaderService,
    FilePickerService? filePickerService,
  }) : _filePickerService = filePickerService ?? FilePickerService();

  @override
  Future<Either<Failure, String?>> call(BackupParams params) async {
    log.info(
      "[BackupUseCase] Backup process started. Platform: ${kIsWeb ? 'Web' : 'Non-Web'}",
    );
    try {
      log.info("[BackupUseCase] Fetching all data...");
      final dataEither = await dataManagementRepository.getAllDataForBackup();
      if (dataEither.isLeft()) {
        log.warning("[BackupUseCase] Failed to retrieve data for backup.");
        return dataEither.fold(
          (failure) => Left(failure),
          (_) => const Left(BackupFailure("Failed to retrieve data.")),
        );
      }
      final allData = dataEither.getOrElse(
        () => throw Exception("Data retrieval error"),
      );
      log.info("[BackupUseCase] Data fetched.");

      log.info("[BackupUseCase] Fetching package info...");
      String appVersion = 'unknown';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (e) {
        log.warning("[BackupUseCase] Could not get package info: $e");
      }
      log.info("[BackupUseCase] App version: $appVersion");

      final backupTimestamp = DateTime.now().toUtc().toIso8601String();
      final backupData = {
        AppConstants.backupMetaKey: {
          AppConstants.backupVersionKey: appVersion,
          AppConstants.backupTimestampKey: backupTimestamp,
          AppConstants.backupFormatVersionKey: AppConstants.backupFormatVersion,
        },
        AppConstants.backupDataKey: allData.toJson(),
      };
      log.info("[BackupUseCase] Backup structure prepared.");

      log.info("[BackupUseCase] Encoding data to JSON...");
      final jsonString = jsonEncode(backupData);
      final encryptedPayload = EncryptionHelper.encryptString(
        jsonString,
        params.password,
      );
      final payloadString = jsonEncode(encryptedPayload);
      final backupFilename =
          '${AppConstants.appName.toLowerCase().replaceAll(' ', '_')}_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      if (kIsWeb) {
        log.info("[BackupUseCase] Platform is Web. Triggering download...");
        try {
          final bytes = utf8.encode(payloadString);
          await downloaderService.downloadFile(
            bytes: Uint8List.fromList(bytes),
            downloadName: backupFilename,
            mimeType: 'application/json',
          );
          log.info(
            "[BackupUseCase] Web download initiated for '$backupFilename'.",
          );
          return const Right('Download started');
        } catch (e, s) {
          log.severe("[BackupUseCase] Error during web download$e$s");
          return Left(
            BackupFailure("Failed to initiate download: ${e.toString()}"),
          );
        }
      } else {
        log.info(
          "[BackupUseCase] Platform is Non-Web. Prompting user for save file location...",
        );
        try {
          final String? outputFile = await _filePickerService.saveFile(
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
          await file.writeAsString(payloadString, flush: true);
          log.info("[BackupUseCase] File written successfully.");
          return Right(finalPath);
        } on PlatformException catch (e, s) {
          log.severe("[BackupUseCase] PlatformException during saveFile$e$s");
          return Left(
            BackupFailure("Could not save file: ${e.message} (${e.code})"),
          );
        } on FileSystemException catch (e, s) {
          log.severe("[BackupUseCase] FileSystemException writing file$e$s");
          return Left(FileSystemFailure("File system error: ${e.message}"));
        } catch (e, s) {
          log.severe("[BackupUseCase] Unexpected error writing file$e$s");
          return Left(
            BackupFailure("Failed to write backup file: ${e.toString()}"),
          );
        }
      }
    } catch (e, s) {
      log.severe("[BackupUseCase] Unexpected error in backup process$e$s");
      return Left(
        BackupFailure(
          "An unexpected error occurred during backup: ${e.toString()}",
        ),
      );
    }
  }
}

class BackupParams {
  final String password;
  const BackupParams(this.password);
}
