import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/encryption_helper.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataManagementRepository extends Mock
    implements DataManagementRepository {}

class FakeFilePickerPlatform extends FilePicker {
  FilePickerResult? result;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return result;
  }
}

void main() {
  late RestoreDataUseCase usecase;
  late MockDataManagementRepository mockRepository;
  late FakeFilePickerPlatform fakePicker;

  setUpAll(() {
    registerFallbackValue(AllData(accounts: [], expenses: [], incomes: []));
  });

  setUp(() {
    mockRepository = MockDataManagementRepository();
    fakePicker = FakeFilePickerPlatform();
    FilePicker.platform = fakePicker;
    usecase = RestoreDataUseCase(mockRepository);
  });

  test('fails when backup format version mismatches', () async {
    const password = 'pw';
    final plainString = jsonEncode({
      AppConstants.backupMetaKey: {AppConstants.backupFormatVersionKey: '0.9'},
      AppConstants.backupDataKey: {
        AppConstants.backupAccountsKey: [],
        AppConstants.backupExpensesKey: [],
        AppConstants.backupIncomesKey: [],
      },
    });

    final encrypted = EncryptionHelper.encryptString(plainString, password);
    final payload = jsonEncode(encrypted);

    fakePicker.result = FilePickerResult([
      PlatformFile(
        name: 'backup.json',
        bytes: Uint8List.fromList(utf8.encode(payload)),
        size: payload.length,
      ),
    ]);

    final result = await usecase(RestoreParams(password));

    expect(
      result,
      equals(
        const Left(RestoreFailure('Backup file format version mismatch.')),
      ),
    );
    verifyNever(() => mockRepository.restoreData(any()));
  });
}
