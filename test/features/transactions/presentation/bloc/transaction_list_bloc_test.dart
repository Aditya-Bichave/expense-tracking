import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/categories/domain/usecases/apply_category_to_batch.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGetTransactionsUseCase extends Mock
    implements GetTransactionsUseCase {}

class MockDeleteExpenseUseCase extends Mock implements DeleteExpenseUseCase {}

class MockDeleteIncomeUseCase extends Mock implements DeleteIncomeUseCase {}

class MockApplyBatchCategoryUseCase extends Mock
    implements ApplyCategoryToBatchUseCase {}

class MockSaveUserCategorizationHistoryUseCase extends Mock
    implements SaveUserCategorizationHistoryUseCase {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(GetTransactionsParams());
    registerFallbackValue(DeleteExpenseParams(''));
    registerFallbackValue(DeleteIncomeParams(''));
    registerFallbackValue(
      ApplyCategoryToBatchParams(
        transactionIds: const [],
        categoryId: '',
        transactionType: TransactionType.expense,
      ),
    );
    registerFallbackValue(
      SaveUserCategorizationHistoryParams(
        transactionData: const TransactionMatchData(description: ''),
        selectedCategory: Category.uncategorized,
      ),
    );
  });

  group('TransactionListBloc delete', () {
    late MockGetTransactionsUseCase getTransactions;
    late MockDeleteExpenseUseCase deleteExpense;
    late MockDeleteIncomeUseCase deleteIncome;
    late MockApplyBatchCategoryUseCase applyBatch;
    late MockSaveUserCategorizationHistoryUseCase saveHistory;
    late MockExpenseRepository expenseRepo;
    late MockIncomeRepository incomeRepo;

    setUp(() {
      getTransactions = MockGetTransactionsUseCase();
      deleteExpense = MockDeleteExpenseUseCase();
      deleteIncome = MockDeleteIncomeUseCase();
      applyBatch = MockApplyBatchCategoryUseCase();
      saveHistory = MockSaveUserCategorizationHistoryUseCase();
      expenseRepo = MockExpenseRepository();
      incomeRepo = MockIncomeRepository();
    });

    blocTest<TransactionListBloc, TransactionListState>(
      'emits deleteError and restores list when deletion fails',
      build: () {
        final bloc = TransactionListBloc(
          getTransactionsUseCase: getTransactions,
          deleteExpenseUseCase: deleteExpense,
          deleteIncomeUseCase: deleteIncome,
          applyCategoryToBatchUseCase: applyBatch,
          saveUserHistoryUseCase: saveHistory,
          expenseRepository: expenseRepo,
          incomeRepository: incomeRepo,
          dataChangeStream: const Stream<DataChangedEvent>.empty(),
        );
        return bloc;
      },
      seed: () {
        final expense = Expense(
          id: '1',
          title: 't',
          amount: 1.0,
          date: DateTime(2024),
          accountId: 'a',
          category: Category.uncategorized,
        );
        final txn = TransactionEntity.fromExpense(expense);
        return TransactionListState(
          status: ListStatus.success,
          transactions: [txn],
        );
      },
      act: (bloc) {
        when(
          () => deleteExpense(any()),
        ).thenAnswer((_) async => Left(ServerFailure('fail')));
        final txn = bloc.state.transactions.first;
        bloc.add(DeleteTransaction(txn));
      },
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.transactions.length,
          'optimistic removal',
          0,
        ),
        isA<TransactionListState>()
            .having((s) => s.transactions.length, 'restored', 1)
            .having((s) => s.deleteError, 'deleteError', isNotNull),
      ],
    );
  });

  group('TransactionListBloc batch apply', () {
    late MockGetTransactionsUseCase getTransactions;
    late MockDeleteExpenseUseCase deleteExpense;
    late MockDeleteIncomeUseCase deleteIncome;
    late MockApplyBatchCategoryUseCase applyBatch;
    late MockSaveUserCategorizationHistoryUseCase saveHistory;
    late MockExpenseRepository expenseRepo;
    late MockIncomeRepository incomeRepo;

    setUp(() {
      getTransactions = MockGetTransactionsUseCase();
      deleteExpense = MockDeleteExpenseUseCase();
      deleteIncome = MockDeleteIncomeUseCase();
      applyBatch = MockApplyBatchCategoryUseCase();
      saveHistory = MockSaveUserCategorizationHistoryUseCase();
      expenseRepo = MockExpenseRepository();
      incomeRepo = MockIncomeRepository();
    });

    blocTest<TransactionListBloc, TransactionListState>(
      'refreshes from repository after successful batch apply',
      build: () {
        when(
          () => applyBatch(any()),
        ).thenAnswer((_) async => const Right(null));
        when(() => getTransactions(any())).thenAnswer(
          (_) async => Right([
            TransactionEntity.fromExpense(
              Expense(
                id: '2',
                title: 'n',
                amount: 2,
                date: DateTime(2024),
                accountId: 'a',
                category: Category.uncategorized,
              ),
            ),
          ]),
        );
        return TransactionListBloc(
          getTransactionsUseCase: getTransactions,
          deleteExpenseUseCase: deleteExpense,
          deleteIncomeUseCase: deleteIncome,
          applyCategoryToBatchUseCase: applyBatch,
          saveUserHistoryUseCase: saveHistory,
          expenseRepository: expenseRepo,
          incomeRepository: incomeRepo,
          dataChangeStream: const Stream<DataChangedEvent>.empty(),
        );
      },
      seed: () {
        final expense = Expense(
          id: '1',
          title: 't',
          amount: 1.0,
          date: DateTime(2024),
          accountId: 'a',
          category: Category.uncategorized,
        );
        final txn = TransactionEntity.fromExpense(expense);
        return TransactionListState(
          status: ListStatus.success,
          transactions: [txn],
          isInBatchEditMode: true,
          selectedTransactionIds: {'1'},
        );
      },
      act: (bloc) => bloc.add(const ApplyBatchCategory('cat1')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.status,
          'initial reloading',
          ListStatus.reloading,
        ),
        isA<TransactionListState>()
            .having((s) => s.isInBatchEditMode, 'batch off', false)
            .having((s) => s.status, 'still reloading', ListStatus.reloading),
        isA<TransactionListState>().having(
          (s) => s.status,
          'load triggered',
          ListStatus.loading,
        ),
        isA<TransactionListState>()
            .having((s) => s.status, 'loaded', ListStatus.success)
            .having((s) => s.transactions.first.id, 'new txn id', '2'),
      ],
    );
  });

  group('TransactionListBloc filtering and sorting', () {
    late MockGetTransactionsUseCase getTransactions;
    late MockDeleteExpenseUseCase deleteExpense;
    late MockDeleteIncomeUseCase deleteIncome;
    late MockApplyBatchCategoryUseCase applyBatch;
    late MockSaveUserCategorizationHistoryUseCase saveHistory;
    late MockExpenseRepository expenseRepo;
    late MockIncomeRepository incomeRepo;

    setUp(() {
      getTransactions = MockGetTransactionsUseCase();
      deleteExpense = MockDeleteExpenseUseCase();
      deleteIncome = MockDeleteIncomeUseCase();
      applyBatch = MockApplyBatchCategoryUseCase();
      saveHistory = MockSaveUserCategorizationHistoryUseCase();
      expenseRepo = MockExpenseRepository();
      incomeRepo = MockIncomeRepository();
    });

    blocTest<TransactionListBloc, TransactionListState>(
      'loads transactions with incoming filters',
      build: () {
        when(() => getTransactions(any())).thenAnswer((_) async => Right([]));
        return TransactionListBloc(
          getTransactionsUseCase: getTransactions,
          deleteExpenseUseCase: deleteExpense,
          deleteIncomeUseCase: deleteIncome,
          applyCategoryToBatchUseCase: applyBatch,
          saveUserHistoryUseCase: saveHistory,
          expenseRepository: expenseRepo,
          incomeRepository: incomeRepo,
          dataChangeStream: const Stream<DataChangedEvent>.empty(),
        );
      },
      act: (bloc) => bloc.add(
        const LoadTransactions(
          incomingFilters: {'categoryId': 'c1', 'accountId': 'a1'},
        ),
      ),
      expect: () => [
        isA<TransactionListState>()
            .having((s) => s.status, 'loading', ListStatus.loading)
            .having((s) => s.categoryId, 'categoryId', 'c1')
            .having((s) => s.accountId, 'accountId', 'a1'),
        isA<TransactionListState>()
            .having((s) => s.status, 'success', ListStatus.success)
            .having((s) => s.categoryId, 'categoryId', 'c1')
            .having((s) => s.accountId, 'accountId', 'a1'),
      ],
      verify: (_) {
        verify(() => getTransactions(any())).called(1);
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'updates filters and reloads',
      build: () {
        when(() => getTransactions(any())).thenAnswer((_) async => Right([]));
        return TransactionListBloc(
          getTransactionsUseCase: getTransactions,
          deleteExpenseUseCase: deleteExpense,
          deleteIncomeUseCase: deleteIncome,
          applyCategoryToBatchUseCase: applyBatch,
          saveUserHistoryUseCase: saveHistory,
          expenseRepository: expenseRepo,
          incomeRepository: incomeRepo,
          dataChangeStream: const Stream<DataChangedEvent>.empty(),
        );
      },
      seed: () => const TransactionListState(status: ListStatus.success),
      act: (bloc) => bloc.add(const FilterChanged(categoryId: 'c1')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.categoryId,
          'categoryId',
          'c1',
        ),
        isA<TransactionListState>()
            .having((s) => s.status, 'reloading', ListStatus.reloading),
        isA<TransactionListState>()
            .having((s) => s.status, 'success', ListStatus.success),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'updates sort and reloads',
      build: () {
        when(() => getTransactions(any())).thenAnswer((_) async => Right([]));
        return TransactionListBloc(
          getTransactionsUseCase: getTransactions,
          deleteExpenseUseCase: deleteExpense,
          deleteIncomeUseCase: deleteIncome,
          applyCategoryToBatchUseCase: applyBatch,
          saveUserHistoryUseCase: saveHistory,
          expenseRepository: expenseRepo,
          incomeRepository: incomeRepo,
          dataChangeStream: const Stream<DataChangedEvent>.empty(),
        );
      },
      seed: () => const TransactionListState(status: ListStatus.success),
      act: (bloc) => bloc.add(
        const SortChanged(
          sortBy: TransactionSortBy.amount,
          sortDirection: SortDirection.ascending,
        ),
      ),
      expect: () => [
        isA<TransactionListState>()
            .having((s) => s.sortBy, 'sortBy', TransactionSortBy.amount)
            .having(
              (s) => s.sortDirection,
              'direction',
              SortDirection.ascending,
            ),
        isA<TransactionListState>()
            .having((s) => s.status, 'reloading', ListStatus.reloading),
        isA<TransactionListState>()
            .having((s) => s.status, 'success', ListStatus.success),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'updates search term and reloads',
      build: () {
        when(() => getTransactions(any())).thenAnswer((_) async => Right([]));
        return TransactionListBloc(
          getTransactionsUseCase: getTransactions,
          deleteExpenseUseCase: deleteExpense,
          deleteIncomeUseCase: deleteIncome,
          applyCategoryToBatchUseCase: applyBatch,
          saveUserHistoryUseCase: saveHistory,
          expenseRepository: expenseRepo,
          incomeRepository: incomeRepo,
          dataChangeStream: const Stream<DataChangedEvent>.empty(),
        );
      },
      seed: () => const TransactionListState(status: ListStatus.success),
      act: (bloc) => bloc.add(const SearchChanged(searchTerm: 'coffee')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.searchTerm,
          'search',
          'coffee',
        ),
        isA<TransactionListState>().having(
          (s) => s.status,
          'reloading',
          ListStatus.reloading,
        ),
        isA<TransactionListState>().having(
          (s) => s.status,
          'success',
          ListStatus.success,
        ),
      ],
    );
  });

  group('TransactionListBloc batch edit toggle', () {
    late MockGetTransactionsUseCase getTransactions;
    late MockDeleteExpenseUseCase deleteExpense;
    late MockDeleteIncomeUseCase deleteIncome;
    late MockApplyBatchCategoryUseCase applyBatch;
    late MockSaveUserCategorizationHistoryUseCase saveHistory;
    late MockExpenseRepository expenseRepo;
    late MockIncomeRepository incomeRepo;

    setUp(() {
      getTransactions = MockGetTransactionsUseCase();
      deleteExpense = MockDeleteExpenseUseCase();
      deleteIncome = MockDeleteIncomeUseCase();
      applyBatch = MockApplyBatchCategoryUseCase();
      saveHistory = MockSaveUserCategorizationHistoryUseCase();
      expenseRepo = MockExpenseRepository();
      incomeRepo = MockIncomeRepository();
    });

    blocTest<TransactionListBloc, TransactionListState>(
      'toggles batch edit mode and clears selection when turning off',
      build: () => TransactionListBloc(
        getTransactionsUseCase: getTransactions,
        deleteExpenseUseCase: deleteExpense,
        deleteIncomeUseCase: deleteIncome,
        applyCategoryToBatchUseCase: applyBatch,
        saveUserHistoryUseCase: saveHistory,
        expenseRepository: expenseRepo,
        incomeRepository: incomeRepo,
        dataChangeStream: const Stream<DataChangedEvent>.empty(),
      ),
      seed: () => const TransactionListState(
        isInBatchEditMode: true,
        selectedTransactionIds: {'1'},
      ),
      act: (bloc) => bloc.add(const ToggleBatchEdit()),
      expect: () => [
        isA<TransactionListState>()
            .having((s) => s.isInBatchEditMode, 'batch off', false)
            .having(
              (s) => s.selectedTransactionIds.isEmpty,
              'selection cleared',
              true,
            ),
      ],
    );
  });
}
