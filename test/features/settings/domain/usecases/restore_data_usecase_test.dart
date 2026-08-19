import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/encryption_helper.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataManagementRepository extends Mock
    implements DataManagementRepository {}

class FakeFilePickerPlatform extends FilePicker {
  FilePickerResult? result;
  Object? throwOnPick;
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
    if (throwOnPick != null) throw throwOnPick!;
    return result;
  }
}

void main() {
  late RestoreDataUseCase usecase;
  late MockDataManagementRepository mockRepository;
  late FakeFilePickerPlatform fakePicker;

  setUpAll(() {
    registerFallbackValue(
      AllData(accounts: [], expenses: [], incomes: [], categories: []),
    );
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

  /// Wraps [plain] the way a real backup file is written: encrypted with
  /// [password], then JSON-encoded as the outer envelope.
  Uint8List backupBytes(String plain, String password) {
    final envelope = jsonEncode(
      EncryptionHelper.encryptString(plain, password),
    );
    return Uint8List.fromList(utf8.encode(envelope));
  }

  void pickBytes(Uint8List? bytes, {String name = 'backup.json'}) {
    fakePicker.result = FilePickerResult([
      PlatformFile(name: name, bytes: bytes, size: bytes?.length ?? 0),
    ]);
  }

  String validBackup({Map<String, dynamic>? data}) => jsonEncode({
    AppConstants.backupMetaKey: {
      AppConstants.backupFormatVersionKey: AppConstants.backupFormatVersion,
    },
    AppConstants.backupDataKey:
        data ??
        {
          AppConstants.backupAccountsKey: <dynamic>[],
          AppConstants.backupExpensesKey: <dynamic>[],
          AppConstants.backupIncomesKey: <dynamic>[],
        },
  });

  String messageOf(Either<Failure, void> result) =>
      result.fold((f) => f.message, (_) => fail('expected a failure'));

  group('file selection', () {
    test('a cancelled picker is reported as a cancellation', () async {
      fakePicker.result = null;

      final result = await usecase(const RestoreParams('pw'));

      expect(messageOf(result), 'Restore cancelled by user.');
      verifyNever(() => mockRepository.restoreData(any()));
    });

    test('a picker returning no files is also a cancellation', () async {
      fakePicker.result = const FilePickerResult([]);

      expect(
        messageOf(await usecase(const RestoreParams('pw'))),
        'Restore cancelled by user.',
      );
    });

    test('a file with no readable bytes is rejected', () async {
      pickBytes(null);

      expect(
        messageOf(await usecase(const RestoreParams('pw'))),
        'Could not read file content.',
      );
    });

    test('a platform error while picking is surfaced with its code', () async {
      fakePicker.throwOnPick = PlatformException(
        code: 'read_external_storage_denied',
        message: 'Permission denied',
      );

      expect(
        messageOf(await usecase(const RestoreParams('pw'))),
        allOf(
          contains('Could not pick file'),
          contains('Permission denied'),
          contains('read_external_storage_denied'),
        ),
      );
    });

    test('an unexpected error is caught rather than escaping', () async {
      fakePicker.throwOnPick = StateError('picker exploded');

      expect(
        messageOf(await usecase(const RestoreParams('pw'))),
        contains('An unexpected error occurred during restore'),
      );
    });
  });

  group('payload validation', () {
    test('a file that is not JSON at all is rejected', () async {
      pickBytes(Uint8List.fromList(utf8.encode('this is not json')));

      expect(
        messageOf(await usecase(const RestoreParams('pw'))),
        'Invalid backup file format (not valid JSON).',
      );
    });

    test('the wrong password is reported as such', () async {
      pickBytes(backupBytes(validBackup(), 'correct-password'));

      expect(
        messageOf(await usecase(const RestoreParams('wrong-password'))),
        'Incorrect password or corrupted backup.',
      );
    });

    test('a backup missing the data section is rejected', () async {
      final plain = jsonEncode({
        AppConstants.backupMetaKey: {
          AppConstants.backupFormatVersionKey: AppConstants.backupFormatVersion,
        },
      });
      pickBytes(backupBytes(plain, 'pw'));

      expect(
        messageOf(await usecase(const RestoreParams('pw'))),
        'Invalid backup file structure.',
      );
    });

    test('a backup whose data section is not a map is rejected', () async {
      final plain = jsonEncode({
        AppConstants.backupMetaKey: {
          AppConstants.backupFormatVersionKey: AppConstants.backupFormatVersion,
        },
        AppConstants.backupDataKey: 'not-a-map',
      });
      pickBytes(backupBytes(plain, 'pw'));

      expect(
        messageOf(await usecase(const RestoreParams('pw'))),
        'Invalid backup file structure.',
      );
    });

    test('data that cannot be deserialized is reported, not thrown', () async {
      // Right shape, wrong contents: accounts must be objects, not numbers.
      final plain = validBackup(
        data: {
          AppConstants.backupAccountsKey: [42],
          AppConstants.backupExpensesKey: <dynamic>[],
          AppConstants.backupIncomesKey: <dynamic>[],
        },
      );
      pickBytes(backupBytes(plain, 'pw'));

      expect(
        messageOf(await usecase(const RestoreParams('pw'))),
        contains('Failed to parse backup data content'),
      );
      verifyNever(() => mockRepository.restoreData(any()));
    });
  });

  group('applying the backup', () {
    setUp(() => pickBytes(backupBytes(validBackup(), 'pw')));

    test('a valid backup is handed to the repository', () async {
      when(
        () => mockRepository.restoreData(any()),
      ).thenAnswer((_) async => const Right(null));

      final result = await usecase(const RestoreParams('pw'));

      expect(result.isRight(), isTrue);
      verify(() => mockRepository.restoreData(any())).called(1);
    });

    test('a repository failure is passed through unchanged', () async {
      when(() => mockRepository.restoreData(any())).thenAnswer(
        (_) async => const Left(CacheFailure('could not clear boxes')),
      );

      final result = await usecase(const RestoreParams('pw'));

      // The original failure must survive; wrapping it would hide the cause.
      expect(
        result.fold((f) => f, (_) => null),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'could not clear boxes',
        ),
      );
    });
  });
}
