import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/categories/domain/usecases/apply_category_to_batch.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTransactionsUseCase extends Mock
    implements GetTransactionsUseCase {}

class MockDeleteExpenseUseCase extends Mock implements DeleteExpenseUseCase {}

class MockDeleteIncomeUseCase extends Mock implements DeleteIncomeUseCase {}

class MockApplyCategoryToBatchUseCase extends Mock
    implements ApplyCategoryToBatchUseCase {}

class MockSaveUserHistoryUseCase extends Mock
    implements SaveUserCategorizationHistoryUseCase {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late TransactionListBloc bloc;
  late MockGetTransactionsUseCase mockGetTransactionsUseCase;
  late MockDeleteExpenseUseCase mockDeleteExpenseUseCase;
  late MockDeleteIncomeUseCase mockDeleteIncomeUseCase;
  late MockApplyCategoryToBatchUseCase mockApplyCategoryToBatchUseCase;
  late MockSaveUserHistoryUseCase mockSaveUserHistoryUseCase;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;
  late StreamController<DataChangedEvent> dataChangeController;

  final tTxnExpense = TransactionEntity(
    id: '1',
    amount: 100,
    date: DateTime(2023, 1, 1),
    type: TransactionType.expense,
    title: 'Lunch',
  );

  setUpAll(() {
    registerFallbackValue(const GetTransactionsParams());
    registerFallbackValue(const DeleteExpenseParams('1'));
    registerFallbackValue(const DeleteIncomeParams('2'));
  });

  setUp(() {
    mockGetTransactionsUseCase = MockGetTransactionsUseCase();
    mockDeleteExpenseUseCase = MockDeleteExpenseUseCase();
    mockDeleteIncomeUseCase = MockDeleteIncomeUseCase();
    mockApplyCategoryToBatchUseCase = MockApplyCategoryToBatchUseCase();
    mockSaveUserHistoryUseCase = MockSaveUserHistoryUseCase();
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    bloc = TransactionListBloc(
      getTransactionsUseCase: mockGetTransactionsUseCase,
      deleteExpenseUseCase: mockDeleteExpenseUseCase,
      deleteIncomeUseCase: mockDeleteIncomeUseCase,
      applyCategoryToBatchUseCase: mockApplyCategoryToBatchUseCase,
      saveUserHistoryUseCase: mockSaveUserHistoryUseCase,
      expenseRepository: mockExpenseRepository,
      incomeRepository: mockIncomeRepository,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() {
    bloc.close();
    dataChangeController.close();
  });

  group('TransactionListBloc', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'emits [loading, success] when LoadTransactions succeeds',
      build: () {
        when(
          () => mockGetTransactionsUseCase(any()),
        ).thenAnswer((_) async => Right([tTxnExpense]));
        return bloc;
      },
      seed: () => const TransactionListState(
        isInBatchEditMode: true,
        selectedTransactionIds: {'1'},
      ),
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.loading,
        ),
        isA<TransactionListState>()
            .having((s) => s.status, 'status', ListStatus.success)
            .having((s) => s.transactions.length, 'transactions', 1)
            .having((s) => s.selectedTransactionIds, 'selectedIds', {'1'}),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'emits [loading, error] when LoadTransactions fails',
      build: () {
        when(
          () => mockGetTransactionsUseCase(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('DB Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.loading,
        ),
        isA<TransactionListState>()
            .having((s) => s.status, 'status', ListStatus.error)
            .having(
              (s) => s.errorMessage,
              'error',
              'Load failed: Database Error: DB Error',
            ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'handles DateTime and String correctly in incomingFilters for startDate and endDate',
      build: () {
        when(
          () => mockGetTransactionsUseCase(any()),
        ).thenAnswer((_) async => Right([tTxnExpense]));
        return bloc;
      },
      act: (bloc) => bloc.add(
        LoadTransactions(
          incomingFilters: {
            'startDate': DateTime(2023, 1, 1),
            'endDate': '2023-12-31T23:59:59.000',
          },
        ),
      ),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.loading,
        ),
        isA<TransactionListState>()
            .having((s) => s.status, 'status', ListStatus.success)
            .having((s) => s.startDate, 'startDate', DateTime(2023, 1, 1))
            .having(
              (s) => s.endDate,
              'endDate',
              DateTime.parse('2023-12-31T23:59:59.000'),
            ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'filters selectedTransactionIds correctly in batch edit mode (O(N*M) fix)',
      build: () {
        when(
          () => mockGetTransactionsUseCase(any()),
        ).thenAnswer((_) async => Right([tTxnExpense]));

        final stateWithSelection = TransactionListState(
          status: ListStatus.initial,
          transactions: const [],
          selectedTransactionIds: const {'1', 'invalid_id'},
          isInBatchEditMode: true,
        );

        return TransactionListBloc(
          getTransactionsUseCase: mockGetTransactionsUseCase,
          deleteExpenseUseCase: mockDeleteExpenseUseCase,
          deleteIncomeUseCase: mockDeleteIncomeUseCase,
          applyCategoryToBatchUseCase: mockApplyCategoryToBatchUseCase,
          saveUserHistoryUseCase: mockSaveUserHistoryUseCase,
          expenseRepository: mockExpenseRepository,
          incomeRepository: mockIncomeRepository,
          dataChangeStream: dataChangeController.stream,
        )..emit(stateWithSelection);
      },
      act: (bloc) => bloc.add(const LoadTransactions(forceReload: true)),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.loading,
        ),
        isA<TransactionListState>()
            .having((s) => s.status, 'status', ListStatus.success)
            .having((s) => s.selectedTransactionIds, 'selected IDs', {
              '1',
            }), // 'invalid_id' is filtered out
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'FilterChanged triggers LoadTransactions',
      build: () {
        when(
          () => mockGetTransactionsUseCase(any()),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(FilterChanged(transactionType: TransactionType.expense)),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.transactionType,
          'type',
          TransactionType.expense,
        ),
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.loading,
        ),
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.success,
        ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'SortChanged triggers LoadTransactions',
      build: () {
        when(
          () => mockGetTransactionsUseCase(any()),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const SortChanged(
          sortBy: TransactionSortBy.amount,
          sortDirection: SortDirection.descending,
        ),
      ),
      expect: () => [
        isA<TransactionListState>()
            .having((s) => s.sortBy, 'sortBy', TransactionSortBy.amount)
            .having(
              (s) => s.sortDirection,
              'sortDir',
              SortDirection.descending,
            ),
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.loading,
        ),
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.success,
        ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'DeleteTransaction optimistically removes item and calls usecase',
      build: () {
        when(
          () => mockGetTransactionsUseCase(any()),
        ).thenAnswer((_) async => Right([tTxnExpense]));
        when(
          () => mockDeleteExpenseUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [tTxnExpense],
      ),
      act: (bloc) => bloc.add(DeleteTransaction(tTxnExpense)),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.transactions.length,
          'transactions',
          0,
        ),
      ],
      verify: (_) {
        verify(() => mockDeleteExpenseUseCase(any())).called(1);
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'reacts to DataChangedEvent from stream',
      build: () {
        when(
          () => mockGetTransactionsUseCase(any()),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => dataChangeController.add(
        const DataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.added,
        ),
      ),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.loading,
        ),
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.success,
        ),
      ],
    );

    group('TransactionListBloc ResetState', () {
      blocTest<TransactionListBloc, TransactionListState>(
        'ResetState emits initial state',
        build: () {
          return bloc;
        },
        seed: () => TransactionListState(
          status: ListStatus.success,
          transactions: [tTxnExpense],
          searchTerm: 'test',
        ),
        act: (bloc) => bloc.add(const ResetState()),
        expect: () => [const TransactionListState()],
      );
    });
  });

  group('_onFetchTransactionById Edge Cases', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'emits error when transaction not found in repositories',
      build: () {
        when(
          () => mockExpenseRepository.getExpenseById('txn-123'),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockIncomeRepository.getIncomeById('txn-123'),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const FetchTransactionById('txn-123')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Transaction not found',
        ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'clears selected transaction',
      build: () => bloc,
      act: (bloc) => bloc.add(const ClearSelectedTransaction()),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.selectedTransaction,
          'selectedTransaction',
          null,
        ),
      ],
    );
  });

  group('_onFetchTransactionById Found Cases', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'emits existing transaction if already in list',
      build: () => bloc,
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [
          tTxnExpense,
        ], // Make sure tTxnExpense exists or we dummy it
      ),
      act: (bloc) => bloc.add(FetchTransactionById(tTxnExpense.id)),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.selectedTransaction,
          'selectedTransaction',
          tTxnExpense,
        ),
      ],
    );
  });

  group('_onFetchTransactionById Found from Repo Cases', () {
    final fixedDate = DateTime(2020);
    final testExpense = Expense(
      id: 'txn-123',
      title: 'test_desc',
      amount: 10,
      date: fixedDate,
      accountId: 'acc1',
    );
    final testIncome = Income(
      id: 'txn-123',
      title: 'test_desc',
      amount: 10,
      date: fixedDate,
      accountId: 'acc1',
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'emits transaction when found in expense repository',
      build: () {
        when(
          () => mockExpenseRepository.getExpenseById('txn-123'),
        ).thenAnswer((_) async => Right(testExpense));
        return bloc;
      },
      act: (bloc) => bloc.add(const FetchTransactionById('txn-123')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.selectedTransaction?.id,
          'id',
          'txn-123',
        ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'emits transaction when found in income repository',
      build: () {
        when(
          () => mockExpenseRepository.getExpenseById('txn-123'),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockIncomeRepository.getIncomeById('txn-123'),
        ).thenAnswer((_) async => Right(testIncome));
        return bloc;
      },
      act: (bloc) => bloc.add(const FetchTransactionById('txn-123')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.selectedTransaction?.id,
          'id',
          'txn-123',
        ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'handles fetch errors gracefully',
      build: () {
        when(
          () => mockExpenseRepository.getExpenseById('txn-123'),
        ).thenAnswer((_) async => const Left(CacheFailure('fail')));
        when(
          () => mockIncomeRepository.getIncomeById('txn-123'),
        ).thenAnswer((_) async => const Left(CacheFailure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(const FetchTransactionById('txn-123')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.errorMessage,
          'err',
          'Transaction not found',
        ),
      ],
    );
  });
}
