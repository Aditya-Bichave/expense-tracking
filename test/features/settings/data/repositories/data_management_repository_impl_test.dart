import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/settings/data/datasources/data_management_local_data_source.dart';
import 'package:expense_tracker/features/settings/data/models/backup_data_model.dart';
import 'package:expense_tracker/features/settings/data/repositories/data_management_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataManagementLocalDataSource extends Mock
    implements DataManagementLocalDataSource {}

void main() {
  late DataManagementRepositoryImpl repository;
  late MockDataManagementLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockDataManagementLocalDataSource();
    repository = DataManagementRepositoryImpl(localDataSource: mockDataSource);
  });

  test('should call getAllDataForBackup on dataSource', () async {
    // Arrange
    final tBackupData = BackupDataModel(
      expenses: [],
      incomes: [],
      accounts: [],
      categories: [],
      budgets: [],
      goals: [],
      goalContributions: [],
      recurringRules: [],
      userHistoryRules: [],
    );
    when(() => mockDataSource.getAllDataForBackup())
        .thenAnswer((_) async => tBackupData);

    // Act
    final result = await repository.getAllDataForBackup();

    // Assert
    expect(result, Right(tBackupData));
    verify(() => mockDataSource.getAllDataForBackup()).called(1);
  });

  test('should call clearAllData on dataSource', () async {
    // Arrange
    when(() => mockDataSource.clearAllData())
        .thenAnswer((_) async => {});

    // Act
    final result = await repository.clearAllData();

    // Assert
    expect(result, const Right(null));
    verify(() => mockDataSource.clearAllData()).called(1);
  });
}
