import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/data/repositories/asset_account_repository_impl.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetAccountLocalDataSource extends Mock
    implements AssetAccountLocalDataSource {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late AssetAccountRepositoryImpl repository;
  late MockAssetAccountLocalDataSource localDataSource;
  late MockIncomeRepository incomeRepository;
  late MockExpenseRepository expenseRepository;

  setUp(() {
    localDataSource = MockAssetAccountLocalDataSource();
    incomeRepository = MockIncomeRepository();
    expenseRepository = MockExpenseRepository();
    repository = AssetAccountRepositoryImpl(
      localDataSource: localDataSource,
      incomeRepository: incomeRepository,
      expenseRepository: expenseRepository,
    );
  });

  test('calculates balances using single income/expense fetch', () async {
    final accounts = [
      AssetAccountModel(
        id: 'a1',
        name: 'A1',
        typeIndex: 0,
        initialBalance: 100,
      ),
      AssetAccountModel(
        id: 'a2',
        name: 'A2',
        typeIndex: 0,
        initialBalance: 200,
      ),
    ];
    when(
      () => localDataSource.getAssetAccounts(),
    ).thenAnswer((_) async => accounts);

    final incomes = [
      IncomeModel(
        id: 'i1',
        title: 'inc1',
        amount: 50,
        date: DateTime.now(),
        accountId: 'a1',
      ),
      IncomeModel(
        id: 'i2',
        title: 'inc2',
        amount: 30,
        date: DateTime.now(),
        accountId: 'a2',
      ),
    ];
    when(
      () => incomeRepository.getIncomes(),
    ).thenAnswer((_) async => Right(incomes));

    final expenses = [
      ExpenseModel(
        id: 'e1',
        title: 'exp1',
        amount: 20,
        date: DateTime.now(),
        accountId: 'a1',
      ),
    ];
    when(
      () => expenseRepository.getExpenses(),
    ).thenAnswer((_) async => Right(expenses));

    final result = await repository.getAssetAccounts();
    expect(result.isRight(), true);
    final list = result.getOrElse(() => []);
    expect(list.length, 2);
    final acc1 = list.firstWhere((a) => a.id == 'a1');
    final acc2 = list.firstWhere((a) => a.id == 'a2');
    expect(acc1.currentBalance, 130); // 100 + 50 - 20
    expect(acc2.currentBalance, 230); // 200 + 30
    verify(() => incomeRepository.getIncomes()).called(1);
    verify(() => expenseRepository.getExpenses()).called(1);
  });
}
