// lib/features/settings/domain/usecases/restore_data_usecase.dart

import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/services.dart'; // Import Uint8List
import 'dart:typed_data'; // Import Uint8List

class RestoreDataUseCase implements UseCase<void, NoParams> {
  final DataManagementRepository dataManagementRepository;

  RestoreDataUseCase(this.dataManagementRepository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    log.info(
        "[RestoreUseCase] Restore process started. Platform: ${kIsWeb ? 'Web' : 'Non-Web'}");
    try {
      // 1. Prompt user to pick a file
      log.info("[RestoreUseCase] Prompting user to pick backup file...");
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // ALWAYS request data bytes
      );

      if (result == null || result.files.isEmpty) {
        log.info(
            "[RestoreUseCase] User cancelled file picker or no file selected.");
        return const Left(RestoreFailure("Restore cancelled by user."));
      }

      final pickedFile = result.files.single;
      log.info("[RestoreUseCase] User selected file: ${pickedFile.name}");

      // 2. Read file content (Use bytes universally)
      log.info("[RestoreUseCase] Reading file content...");
      final Uint8List? fileBytes = pickedFile.bytes;

      // --- CORRECTED: Declare jsonString *before* the if ---
      String jsonString;
      // -----------------------------------------------------

      if (fileBytes == null) {
        log.severe("[RestoreUseCase] File picker did not return bytes.");
        // Check path as fallback for non-web? Might be inconsistent.
        if (!kIsWeb && pickedFile.path != null) {
          log.info(
              "[RestoreUseCase] Attempting to read from path as fallback: ${pickedFile.path}");
          try {
            final file = File(pickedFile.path!);
            final fallbackBytes = await file.readAsBytes();
            // Assign to the already declared jsonString
            jsonString = utf8.decode(fallbackBytes);
          } catch (e, s) {
            log.severe(
                "[RestoreUseCase] Failed to read from path fallback.$e$s");
            return const Left(RestoreFailure("Could not read file content."));
          }
        } else {
          return const Left(RestoreFailure("Could not read file content."));
        }
      } else {
        // If fileBytes is NOT null, decode them directly
        try {
          // Decode bytes assuming UTF-8
          // Assign to the already declared jsonString
          jsonString = utf8.decode(fileBytes);
          log.info(
              "[RestoreUseCase] File content read and decoded (${jsonString.length} chars).");
        } catch (e, s) {
          log.severe("[RestoreUseCase] Error decoding file bytes$e$s");
          return Left(
              RestoreFailure("Failed to decode file content: ${e.toString()}"));
        }
      }

      // 3. Decode and Validate JSON (Now jsonString is guaranteed to be assigned if successful)
      log.info("[RestoreUseCase] Decoding JSON...");
      Map<String, dynamic> decodedJson;
      try {
        decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        log.warning("[RestoreUseCase] JSON decoding error: $e");
        return const Left(
            RestoreFailure("Invalid backup file format (not valid JSON)."));
      }
      log.info("[RestoreUseCase] JSON decoded.");

      // Basic structure validation
      if (!decodedJson.containsKey('data') ||
          decodedJson['data'] is! Map ||
          !decodedJson.containsKey('metadata')) {
        log.warning(
            "[RestoreUseCase] Invalid backup format: Missing 'data' or 'metadata'.");
        return const Left(RestoreFailure("Invalid backup file structure."));
      }

      final dataMap = decodedJson['data'] as Map<String, dynamic>;

      // 4. Deserialize data
      log.info("[RestoreUseCase] Deserializing data from JSON...");
      AllData allData;
      try {
        allData = AllData.fromJson(dataMap);
        log.info("[RestoreUseCase] Deserialization successful.");
      } catch (e, s) {
        log.severe("[RestoreUseCase] Error during deserialization");
        return Left(RestoreFailure(
            "Failed to parse backup data content: ${e.toString()}"));
      }

      // 5. Restore data via repository (includes clearing)
      log.info("[RestoreUseCase] Calling repository.restoreData...");
      final restoreResult = await dataManagementRepository.restoreData(allData);

      return restoreResult.fold(
        (failure) {
          log.severe(// Use severe for repository failure
              "[RestoreUseCase] Repository restore failed: ${failure.message}");
          return Left(failure);
        },
        (_) {
          log.info("[RestoreUseCase] Repository restore successful.");
          return const Right(null); // Success
        },
      );
    } on PlatformException catch (e, s) {
      log.severe(
          // Use severe for platform exceptions
          "[RestoreUseCase] PlatformException during file picking$e$s");
      return Left(
          RestoreFailure("Could not pick file: ${e.message} (${e.code})"));
    } catch (e, s) {
      log.severe(
          "[RestoreUseCase] Unexpected error in restore process$e$s"); // Use severe
      return Left(RestoreFailure(
          "An unexpected error occurred during restore: ${e.toString()}"));
    }
  }
}
