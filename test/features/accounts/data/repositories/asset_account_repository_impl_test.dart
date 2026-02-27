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
  late MockAssetAccountLocalDataSource mockLocalDataSource;
  late MockIncomeRepository mockIncomeRepository;
  late MockExpenseRepository mockExpenseRepository;

  setUp(() {
    mockLocalDataSource = MockAssetAccountLocalDataSource();
    mockIncomeRepository = MockIncomeRepository();
    mockExpenseRepository = MockExpenseRepository();
    repository = AssetAccountRepositoryImpl(
      localDataSource: mockLocalDataSource,
      incomeRepository: mockIncomeRepository,
      expenseRepository: mockExpenseRepository,
    );
    registerFallbackValue(
      AssetAccountModel(
        id: '1',
        name: 'Bank',
        initialBalance: 1000,
        typeIndex: 0,
      ),
    );
  });

  final tAccount = AssetAccount(
    id: '1',
    name: 'Bank',
    type: AssetType.bank,
    initialBalance: 1000,
    currentBalance: 1000,
  );

  group('getAssetAccounts', () {
    test('should return accounts with calculated balance', () async {
      final model = AssetAccountModel(
        id: '1',
        name: 'Bank',
        initialBalance: 1000,
        typeIndex: 0,
      );

      when(
        () => mockLocalDataSource.getAssetAccounts(),
      ).thenAnswer((_) async => [model]);

      // Mock incomes/expenses for balance calc
      when(() => mockIncomeRepository.getIncomes()).thenAnswer((_) async => const Right([]));
      when(() => mockExpenseRepository.getExpenses()).thenAnswer((_) async => const Right([]));

      final result = await repository.getAssetAccounts();

      expect(result.isRight(), true);
      result.fold((l) => null, (list) {
        expect(list.length, 1);
        expect(list.first.currentBalance, 1000.0);
      });
    });
  });

  group('addAssetAccount', () {
    test('should save account and return entity', () async {
      // The interface returns Future<AssetAccountModel>
      when(
        () => mockLocalDataSource.addAssetAccount(any()),
      ).thenAnswer((invocation) async => invocation.positionalArguments[0] as AssetAccountModel);

      // Mocks for _calculateBalance
      when(
        () => mockIncomeRepository.getTotalIncomeForAccount('1'),
      ).thenAnswer((_) async => const Right(0.0));
      when(
        () => mockExpenseRepository.getTotalExpensesForAccount('1'),
      ).thenAnswer((_) async => const Right(0.0));

      final result = await repository.addAssetAccount(tAccount);

      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.addAssetAccount(any())).called(1);
    });
  });
}
