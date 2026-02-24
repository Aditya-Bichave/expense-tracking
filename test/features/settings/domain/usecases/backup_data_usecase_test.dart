import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/downloader_service.dart';
import 'package:expense_tracker/core/services/file_picker_service.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:io';

class MockDataManagementRepository extends Mock
    implements DataManagementRepository {}

class MockDownloaderService extends Mock implements DownloaderService {}

class MockFilePickerService extends Mock implements FilePickerService {}

void main() {
  late BackupDataUseCase useCase;
  late MockDataManagementRepository mockDataManagementRepository;
  late MockDownloaderService mockDownloaderService;
  late MockFilePickerService mockFilePickerService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock PackageInfo channel
    const MethodChannel(
      'dev.fluttercommunity.plus/package_info',
    ).setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'Expense Tracker',
          'packageName': 'com.example.expense_tracker',
          'version': '1.0.0',
          'buildNumber': '1',
        };
      }
      return null;
    });
  });

  setUp(() {
    mockDataManagementRepository = MockDataManagementRepository();
    mockDownloaderService = MockDownloaderService();
    mockFilePickerService = MockFilePickerService();
    useCase = BackupDataUseCase(
      dataManagementRepository: mockDataManagementRepository,
      downloaderService: mockDownloaderService,
      filePickerService: mockFilePickerService,
    );
  });

  test('returns BackupFailure when data retrieval fails', () async {
    when(
      () => mockDataManagementRepository.getAllDataForBackup(),
    ).thenAnswer((_) async => const Left(BackupFailure('Data error')));

    final result = await useCase(const BackupParams('password'));

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<BackupFailure>()),
      (_) => fail('Should be Left'),
    );
  });

  test('calls saveFile via service and handles success', () async {
    final allData = AllData(
      accounts: <AssetAccountModel>[],
      expenses: <ExpenseModel>[],
      incomes: <IncomeModel>[],
    );
    when(
      () => mockDataManagementRepository.getAllDataForBackup(),
    ).thenAnswer((_) async => Right(allData));

    // Mock saveFile to return a path
    final tempDir = Directory.systemTemp.createTempSync();
    final tempPath = '${tempDir.path}/backup.json';

    when(
      () => mockFilePickerService.saveFile(
        dialogTitle: any(named: 'dialogTitle'),
        fileName: any(named: 'fileName'),
        allowedExtensions: any(named: 'allowedExtensions'),
      ),
    ).thenAnswer((_) async => tempPath);

    final result = await useCase(const BackupParams('password'));

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('Should be Right'),
      (path) => expect(path, endsWith('.json')),
    );

    // Verify file was written
    final file = File(tempPath);
    expect(file.existsSync(), isTrue);
    final content = file.readAsStringSync();
    // The content is encrypted, so we expect encryption fields
    expect(content, contains('cipher'));
    expect(content, contains('iv'));
    expect(content, contains('salt'));

    // Cleanup
    if (file.existsSync()) file.deleteSync();
  });

  test('handles user cancellation in file picker', () async {
    final allData = AllData(
      accounts: <AssetAccountModel>[],
      expenses: <ExpenseModel>[],
      incomes: <IncomeModel>[],
    );
    when(
      () => mockDataManagementRepository.getAllDataForBackup(),
    ).thenAnswer((_) async => Right(allData));

    // Mock saveFile to return null (cancel)
    when(
      () => mockFilePickerService.saveFile(
        dialogTitle: any(named: 'dialogTitle'),
        fileName: any(named: 'fileName'),
        allowedExtensions: any(named: 'allowedExtensions'),
      ),
    ).thenAnswer((_) async => null);

    final result = await useCase(const BackupParams('password'));

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<BackupFailure>());
      expect(failure.message, contains('Backup cancelled'));
    }, (_) => fail('Should be Left'));
  });
}
