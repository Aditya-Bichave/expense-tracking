import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/data/repositories/asset_account_repository_impl.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetAccountLocalDataSource extends Mock
    implements AssetAccountLocalDataSource {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late AssetAccountRepositoryImpl repository;
  late MockAssetAccountLocalDataSource mockDataSource;
  late MockIncomeRepository mockIncomeRepository;
  late MockExpenseRepository mockExpenseRepository;

  setUpAll(() {
    registerFallbackValue(
      AssetAccountModel(id: '', name: '', typeIndex: 0, initialBalance: 0),
    );
  });

  setUp(() {
    mockDataSource = MockAssetAccountLocalDataSource();
    mockIncomeRepository = MockIncomeRepository();
    mockExpenseRepository = MockExpenseRepository();
    repository = AssetAccountRepositoryImpl(
      localDataSource: mockDataSource,
      incomeRepository: mockIncomeRepository,
      expenseRepository: mockExpenseRepository,
    );
  });

  final tAccount = AssetAccount(
    id: '1',
    name: 'Cash',
    type: AssetType.cash,
    initialBalance: 100,
    currentBalance: 100,
  );
  final tAccountModel = AssetAccountModel.fromEntity(tAccount);

  test('should add account and recalculate balance', () async {
    // Arrange
    when(
      () => mockDataSource.addAssetAccount(any()),
    ).thenAnswer((_) async => tAccountModel);
    when(
      () => mockIncomeRepository.getTotalIncomeForAccount('1'),
    ).thenAnswer((_) async => const Right(50.0));
    when(
      () => mockExpenseRepository.getTotalExpensesForAccount('1'),
    ).thenAnswer((_) async => const Right(20.0));

    // Act
    final result = await repository.addAssetAccount(tAccount);

    // Assert
    // 100 + 50 - 20 = 130
    expect(result.isRight(), true);
    result.fold((l) => fail('Should be Right, but was Left: $l'), (r) {
      expect(r.currentBalance, 130.0);
      expect(r.id, tAccount.id);
    });

    verify(() => mockDataSource.addAssetAccount(any())).called(1);
  });

  test('should delete account if no transactions linked', () async {
    // Arrange
    when(
      () => mockIncomeRepository.getIncomes(accountId: '1'),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockExpenseRepository.getExpenses(accountId: '1'),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockDataSource.deleteAssetAccount('1'),
    ).thenAnswer((_) async => Future.value());

    // Act
    final result = await repository.deleteAssetAccount('1');

    // Assert
    expect(result, const Right(null));
    verify(() => mockDataSource.deleteAssetAccount('1')).called(1);
  });
}
