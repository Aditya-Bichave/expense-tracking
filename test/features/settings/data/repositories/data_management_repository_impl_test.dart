import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/settings/data/repositories/data_management_repository_impl.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox<T> extends Mock implements Box<T> {}

void main() {
  late DataManagementRepositoryImpl repository;
  late MockBox<AssetAccountModel> mockAccountBox;
  late MockBox<ExpenseModel> mockExpenseBox;
  late MockBox<IncomeModel> mockIncomeBox;

  setUp(() {
    mockAccountBox = MockBox<AssetAccountModel>();
    mockExpenseBox = MockBox<ExpenseModel>();
    mockIncomeBox = MockBox<IncomeModel>();
    repository = DataManagementRepositoryImpl(
      accountBox: mockAccountBox,
      expenseBox: mockExpenseBox,
      incomeBox: mockIncomeBox,
    );
  });

  test('should gather all data for backup', () async {
    // Arrange
    when(() => mockAccountBox.values).thenReturn([]);
    when(() => mockExpenseBox.values).thenReturn([]);
    when(() => mockIncomeBox.values).thenReturn([]);

    // Act
    final result = await repository.getAllDataForBackup();

    // Assert
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Should be Right'),
      (allData) {
        expect(allData.accounts, isEmpty);
        expect(allData.expenses, isEmpty);
        expect(allData.incomes, isEmpty);
      },
    );
  });

  test('should clear all data', () async {
    // Arrange
    when(() => mockAccountBox.clear()).thenAnswer((_) async => 0);
    when(() => mockExpenseBox.clear()).thenAnswer((_) async => 0);
    when(() => mockIncomeBox.clear()).thenAnswer((_) async => 0);

    // Act
    final result = await repository.clearAllData();

    // Assert
    expect(result, const Right(null));
    verify(() => mockAccountBox.clear()).called(1);
    verify(() => mockExpenseBox.clear()).called(1);
    verify(() => mockIncomeBox.clear()).called(1);
  });
}
