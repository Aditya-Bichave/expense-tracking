import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/data/repositories/asset_account_repository_impl.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
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

class _FakeAssetAccountModel extends Fake implements AssetAccountModel {}

T rightOf<T>(Either<Failure, T> either) =>
    either.fold((l) => fail('expected a success, got $l'), (r) => r);

Failure leftOf<T>(Either<Failure, T> either) =>
    either.fold((l) => l, (r) => fail('expected a failure, got $r'));

void main() {
  late MockAssetAccountLocalDataSource dataSource;
  late MockIncomeRepository incomeRepository;
  late MockExpenseRepository expenseRepository;
  late AssetAccountRepositoryImpl repository;

  const account = AssetAccount(
    id: 'a1',
    name: 'Bank',
    type: AssetType.bank,
    initialBalance: 1000,
    currentBalance: 1000,
  );

  AssetAccountModel accountModel({
    String id = 'a1',
    String name = 'Bank',
    double initialBalance = 1000,
  }) => AssetAccountModel(
    id: id,
    name: name,
    initialBalance: initialBalance,
    typeIndex: 0,
  );

  IncomeModel income(String accountId, double amount, [String id = 'i1']) =>
      IncomeModel(
        id: id,
        title: 'Salary',
        amount: amount,
        date: DateTime(2024, 1, 1),
        accountId: accountId,
      );

  ExpenseModel expense(String accountId, double amount, [String id = 'e1']) =>
      ExpenseModel(
        id: id,
        title: 'Rent',
        amount: amount,
        date: DateTime(2024, 1, 1),
        accountId: accountId,
      );

  setUpAll(() {
    registerFallbackValue(_FakeAssetAccountModel());
  });

  setUp(() {
    dataSource = MockAssetAccountLocalDataSource();
    incomeRepository = MockIncomeRepository();
    expenseRepository = MockExpenseRepository();
    repository = AssetAccountRepositoryImpl(
      localDataSource: dataSource,
      incomeRepository: incomeRepository,
      expenseRepository: expenseRepository,
    );
  });

  void stubTotals({
    Either<Failure, double> incomeTotal = const Right(0),
    Either<Failure, double> expenseTotal = const Right(0),
  }) {
    when(
      () => incomeRepository.getTotalIncomeForAccount(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => incomeTotal);
    when(
      () => expenseRepository.getTotalExpensesForAccount(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => expenseTotal);
  }

  group('addAssetAccount', () {
    test(
      'persists the account and returns it with a computed balance',
      () async {
        when(() => dataSource.addAssetAccount(any())).thenAnswer(
          (i) async => i.positionalArguments.first as AssetAccountModel,
        );
        stubTotals(
          incomeTotal: const Right(500),
          expenseTotal: const Right(200),
        );

        final result = await repository.addAssetAccount(account);

        // 1000 initial + 500 income - 200 expenses.
        expect(rightOf(result).currentBalance, 1300);
        verify(() => dataSource.addAssetAccount(any())).called(1);
      },
    );

    test('propagates a failure from the income side of the balance', () async {
      when(() => dataSource.addAssetAccount(any())).thenAnswer(
        (i) async => i.positionalArguments.first as AssetAccountModel,
      );
      stubTotals(incomeTotal: const Left(CacheFailure('income box closed')));

      final result = await repository.addAssetAccount(account);

      expect(
        leftOf(result),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'income box closed',
        ),
      );
    });

    test('propagates a failure from the expense side of the balance', () async {
      when(() => dataSource.addAssetAccount(any())).thenAnswer(
        (i) async => i.positionalArguments.first as AssetAccountModel,
      );
      stubTotals(expenseTotal: const Left(CacheFailure('expense box closed')));

      final result = await repository.addAssetAccount(account);

      expect(leftOf(result), isA<CacheFailure>());
    });

    test('propagates a CacheFailure raised by the data source', () async {
      when(
        () => dataSource.addAssetAccount(any()),
      ).thenThrow(const CacheFailure('write failed'));

      final result = await repository.addAssetAccount(account);

      expect(
        leftOf(result),
        isA<CacheFailure>().having((f) => f.message, 'message', 'write failed'),
      );
    });

    test('wraps an unexpected error as CacheFailure', () async {
      when(() => dataSource.addAssetAccount(any())).thenThrow(StateError('x'));

      final result = await repository.addAssetAccount(account);

      expect(
        leftOf(result),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          contains('Failed to add account'),
        ),
      );
    });
  });

  group('updateAssetAccount', () {
    test('persists the update and recomputes the balance', () async {
      when(() => dataSource.updateAssetAccount(any())).thenAnswer(
        (i) async => i.positionalArguments.first as AssetAccountModel,
      );
      stubTotals(incomeTotal: const Right(0), expenseTotal: const Right(250));

      final result = await repository.updateAssetAccount(account);

      expect(rightOf(result).currentBalance, 750);
      verify(() => dataSource.updateAssetAccount(any())).called(1);
    });

    test('propagates a balance failure', () async {
      when(() => dataSource.updateAssetAccount(any())).thenAnswer(
        (i) async => i.positionalArguments.first as AssetAccountModel,
      );
      stubTotals(incomeTotal: const Left(CacheFailure('nope')));

      expect(
        leftOf(await repository.updateAssetAccount(account)),
        isA<CacheFailure>(),
      );
    });

    test('propagates a CacheFailure from the data source', () async {
      when(
        () => dataSource.updateAssetAccount(any()),
      ).thenThrow(const CacheFailure('locked'));

      expect(
        leftOf(await repository.updateAssetAccount(account)),
        isA<CacheFailure>().having((f) => f.message, 'message', 'locked'),
      );
    });

    test('wraps an unexpected error as CacheFailure', () async {
      when(
        () => dataSource.updateAssetAccount(any()),
      ).thenThrow(Exception('boom'));

      expect(
        leftOf(await repository.updateAssetAccount(account)),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          contains('Failed to update account'),
        ),
      );
    });
  });

  group('deleteAssetAccount', () {
    void stubLinked({
      Either<Failure, List<IncomeModel>> incomes = const Right([]),
      Either<Failure, List<ExpenseModel>> expenses = const Right([]),
    }) {
      when(
        () => incomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => incomes);
      when(
        () => expenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => expenses);
    }

    test('deletes when the account has no linked transactions', () async {
      stubLinked();
      when(() => dataSource.deleteAssetAccount('a1')).thenAnswer((_) async {});

      final result = await repository.deleteAssetAccount('a1');

      expect(result.isRight(), isTrue);
      verify(() => dataSource.deleteAssetAccount('a1')).called(1);
    });

    test('refuses to delete an account that still has income', () async {
      stubLinked(incomes: Right([income('a1', 100)]));

      final result = await repository.deleteAssetAccount('a1');

      expect(
        leftOf(result),
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('Cannot delete account with existing income or expenses'),
        ),
      );
      verifyNever(() => dataSource.deleteAssetAccount(any()));
    });

    test('refuses to delete an account that still has expenses', () async {
      stubLinked(expenses: Right([expense('a1', 40)]));

      expect(
        leftOf(await repository.deleteAssetAccount('a1')),
        isA<ValidationFailure>(),
      );
      verifyNever(() => dataSource.deleteAssetAccount(any()));
    });

    test('refuses to delete when the linkage check itself fails', () async {
      stubLinked(incomes: const Left(CacheFailure('income read error')));

      final result = await repository.deleteAssetAccount('a1');

      expect(
        leftOf(result),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          contains('Could not verify linked transactions'),
        ),
      );
      verifyNever(() => dataSource.deleteAssetAccount(any()));
    });

    test('reports both check failures together', () async {
      stubLinked(
        incomes: const Left(CacheFailure('income read error')),
        expenses: const Left(CacheFailure('expense read error')),
      );

      final message = leftOf(await repository.deleteAssetAccount('a1')).message;

      expect(message, contains('income read error'));
      expect(message, contains('expense read error'));
    });

    test('propagates a CacheFailure from the delete itself', () async {
      stubLinked();
      when(
        () => dataSource.deleteAssetAccount('a1'),
      ).thenThrow(const CacheFailure('delete failed'));

      expect(
        leftOf(await repository.deleteAssetAccount('a1')),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'delete failed',
        ),
      );
    });

    test('wraps an unexpected delete error as CacheFailure', () async {
      stubLinked();
      when(
        () => dataSource.deleteAssetAccount('a1'),
      ).thenThrow(StateError('x'));

      expect(
        leftOf(await repository.deleteAssetAccount('a1')).message,
        contains('Failed to delete account'),
      );
    });
  });

  group('getAssetAccounts', () {
    void stubAll({
      required List<AssetAccountModel> accounts,
      Either<Failure, List<IncomeModel>> incomes = const Right([]),
      Either<Failure, List<ExpenseModel>> expenses = const Right([]),
    }) {
      when(
        () => dataSource.getAssetAccounts(),
      ).thenAnswer((_) async => accounts);
      when(
        () => incomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => incomes);
      when(
        () => expenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => expenses);
    }

    test('computes each account balance from a single bulk fetch', () async {
      stubAll(
        accounts: [
          accountModel(id: 'a1', name: 'Bank', initialBalance: 1000),
          accountModel(id: 'a2', name: 'Cash', initialBalance: 100),
        ],
        incomes: Right([
          income('a1', 500, 'i1'),
          income('a1', 250, 'i2'),
          income('a2', 20, 'i3'),
        ]),
        expenses: Right([expense('a1', 300, 'e1'), expense('a2', 5, 'e2')]),
      );

      final accounts = rightOf(await repository.getAssetAccounts());

      expect(accounts, hasLength(2));
      // 1000 + (500+250) - 300
      expect(accounts[0].currentBalance, 1450);
      // 100 + 20 - 5
      expect(accounts[1].currentBalance, 115);
      // The N+1 guard: exactly one income and one expense fetch for N accounts.
      verify(
        () => incomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).called(1);
    });

    test('an account with no transactions keeps its initial balance', () async {
      stubAll(accounts: [accountModel(id: 'a9', initialBalance: 42)]);

      final accounts = rightOf(await repository.getAssetAccounts());

      expect(accounts.single.currentBalance, 42);
    });

    test('returns an empty list when there are no accounts', () async {
      stubAll(accounts: []);

      expect(rightOf(await repository.getAssetAccounts()), isEmpty);
    });

    test('propagates an income fetch failure', () async {
      stubAll(
        accounts: [accountModel()],
        incomes: const Left(CacheFailure('income unavailable')),
      );

      expect(
        leftOf(await repository.getAssetAccounts()),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'income unavailable',
        ),
      );
    });

    test('propagates an expense fetch failure', () async {
      stubAll(
        accounts: [accountModel()],
        expenses: const Left(CacheFailure('expense unavailable')),
      );

      expect(
        leftOf(await repository.getAssetAccounts()),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'expense unavailable',
        ),
      );
    });

    test('propagates a CacheFailure from the account fetch', () async {
      when(
        () => dataSource.getAssetAccounts(),
      ).thenThrow(const CacheFailure('accounts box closed'));

      expect(
        leftOf(await repository.getAssetAccounts()),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'accounts box closed',
        ),
      );
    });

    test('wraps an unexpected error as CacheFailure', () async {
      when(() => dataSource.getAssetAccounts()).thenThrow(StateError('x'));

      expect(
        leftOf(await repository.getAssetAccounts()).message,
        contains('Failed to get accounts'),
      );
    });
  });
}
