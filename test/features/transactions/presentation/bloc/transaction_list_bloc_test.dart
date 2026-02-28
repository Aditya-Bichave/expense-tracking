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
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.loading,
        ),
        isA<TransactionListState>()
            .having((s) => s.status, 'status', ListStatus.success)
            .having((s) => s.transactions.length, 'transactions', 1),
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
}
