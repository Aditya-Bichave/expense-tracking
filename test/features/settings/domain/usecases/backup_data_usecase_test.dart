import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/downloader_service.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataManagementRepository extends Mock
    implements DataManagementRepository {}

class MockDownloaderService extends Mock implements DownloaderService {}

void main() {
  late BackupDataUseCase useCase;
  late MockDataManagementRepository mockDataManagementRepository;
  late MockDownloaderService mockDownloaderService;

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
    useCase = BackupDataUseCase(
      dataManagementRepository: mockDataManagementRepository,
      downloaderService: mockDownloaderService,
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

  test(
    'handles FilePicker initialization error gracefully (since we cannot mock static FilePicker.platform)',
    () async {
      // This test verifies that we reach the FilePicker call.
      // Since we cannot mock the static FilePicker.platform without refactoring,
      // we expect the LateInitializationError which is caught and wrapped in BackupFailure.

      final allData = AllData(
        accounts: <AssetAccountModel>[],
        expenses: <ExpenseModel>[],
        incomes: <IncomeModel>[],
      );
      when(
        () => mockDataManagementRepository.getAllDataForBackup(),
      ).thenAnswer((_) async => Right(allData));

      final result = await useCase(const BackupParams('password'));

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<BackupFailure>());
        // Check that it failed due to writing file (which implies it passed data preparation)
        // The specific error is "Failed to write backup file: LateInitializationError..."
        expect(failure.message, contains('Failed to write backup file'));
      }, (_) => fail('Should be Left'));
    },
  );
}
