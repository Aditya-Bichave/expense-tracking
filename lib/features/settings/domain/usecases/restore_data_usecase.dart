// features/settings/domain/usecases/restore_data_usecase.dart

import 'dart:convert';
import 'dart:io'; // Needed for non-web File access
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb and debugPrint
import 'dart:typed_data'; // For Uint8List on web

class RestoreFailure extends Failure {
  const RestoreFailure(String message) : super(message);
}

class RestoreDataUseCase implements UseCase<void, NoParams> {
  final DataManagementRepository dataManagementRepository;

  RestoreDataUseCase(this.dataManagementRepository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    debugPrint(
        "[RestoreUseCase] Restore process started. Platform: ${kIsWeb ? 'Web' : 'Non-Web'}");
    try {
      // 1. Prompt user to pick a file
      debugPrint("[RestoreUseCase] Prompting user to pick backup file...");
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: kIsWeb, // <<< IMPORTANT: Request file data (bytes) on web
      );

      if (result == null || result.files.isEmpty) {
        debugPrint(
            "[RestoreUseCase] User cancelled file picker or no file selected.");
        return const Left(RestoreFailure("Restore cancelled by user."));
      }

      final pickedFile = result.files.single;
      debugPrint("[RestoreUseCase] User selected file: ${pickedFile.name}");

      // 2. Read file content (Platform Specific)
      String jsonString;
      debugPrint("[RestoreUseCase] Reading file content...");
      if (kIsWeb) {
        // --- Web: Read from bytes ---
        final Uint8List? fileBytes = pickedFile.bytes;
        if (fileBytes == null) {
          debugPrint("[RestoreUseCase] Web file picker did not return bytes.");
          return const Left(
              RestoreFailure("Could not read file content from browser."));
        }
        try {
          // Decode bytes directly to String assuming UTF-8
          jsonString = utf8.decode(fileBytes);
          debugPrint(
              "[RestoreUseCase] Web file content read and decoded (${jsonString.length} chars).");
        } catch (e) {
          debugPrint("[RestoreUseCase] Error decoding web file bytes: $e");
          return Left(
              RestoreFailure("Failed to decode file content: ${e.toString()}"));
        }
        // --- End Web Logic ---
      } else {
        // --- Non-Web: Read from path ---
        final String? filePath = pickedFile.path;
        if (filePath == null) {
          debugPrint(
              "[RestoreUseCase] Non-web file picker did not return path.");
          return const Left(RestoreFailure("Could not get file path."));
        }
        final file = File(filePath);
        try {
          jsonString = await file.readAsString();
          debugPrint(
              "[RestoreUseCase] Non-web file content read (${jsonString.length} chars).");
        } on FileSystemException catch (e) {
          debugPrint("[RestoreUseCase] FileSystemException reading file: $e");
          return Left(
              RestoreFailure("Could not read backup file: ${e.message}"));
        } catch (e) {
          debugPrint("[RestoreUseCase] Error reading file: $e");
          return Left(
              RestoreFailure("Failed to read backup file: ${e.toString()}"));
        }
        // --- End Non-Web Logic ---
      }

      // 3. Decode and Validate JSON (Same for both platforms)
      debugPrint("[RestoreUseCase] Decoding JSON...");
      Map<String, dynamic> decodedJson;
      try {
        decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        debugPrint("[RestoreUseCase] JSON decoding error: $e");
        return const Left(
            RestoreFailure("Invalid backup file format (not valid JSON)."));
      }
      debugPrint("[RestoreUseCase] JSON decoded.");

      if (!decodedJson.containsKey('data') || decodedJson['data'] is! Map) {
        debugPrint(
            "[RestoreUseCase] Invalid backup format: Missing 'data' key or not a map.");
        return const Left(RestoreFailure(
            "Invalid backup file structure (missing 'data' section)."));
      }
      final dataMap = decodedJson['data'] as Map<String, dynamic>;
      // TODO: Add more validation if needed (e.g., check metadata version)

      // 4. Deserialize data (Same for both platforms)
      debugPrint("[RestoreUseCase] Deserializing data from JSON...");
      AllData allData;
      try {
        allData = AllData.fromJson(dataMap);
        debugPrint("[RestoreUseCase] Deserialization successful.");
      } catch (e, s) {
        debugPrint("[RestoreUseCase] Error during deserialization: $e\n$s");
        return Left(RestoreFailure(
            "Failed to parse backup data content: ${e.toString()}"));
      }

      // 5. Restore data via repository (includes clearing)
      debugPrint("[RestoreUseCase] Calling repository.restoreData...");
      final restoreResult = await dataManagementRepository.restoreData(allData);

      return restoreResult.fold(
        (failure) {
          debugPrint(
              "[RestoreUseCase] Repository restore failed: ${failure.message}");
          return Left(failure);
        },
        (_) {
          debugPrint("[RestoreUseCase] Repository restore successful.");
          return const Right(null); // Success
        },
      );
    } catch (e, s) {
      debugPrint("[RestoreUseCase] Unexpected error: $e\n$s");
      return Left(RestoreFailure(
          "An unexpected error occurred during restore: ${e.toString()}"));
    }
  }
}
