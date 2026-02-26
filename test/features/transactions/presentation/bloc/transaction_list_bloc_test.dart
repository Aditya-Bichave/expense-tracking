import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
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

class MockSaveUserCategorizationHistoryUseCase extends Mock
    implements SaveUserCategorizationHistoryUseCase {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late MockGetTransactionsUseCase mockGetTransactionsUseCase;
  late MockDeleteExpenseUseCase mockDeleteExpenseUseCase;
  late MockDeleteIncomeUseCase mockDeleteIncomeUseCase;
  late MockApplyCategoryToBatchUseCase mockApplyCategoryToBatchUseCase;
  late MockSaveUserCategorizationHistoryUseCase
  mockSaveUserCategorizationHistoryUseCase;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;
  late StreamController<DataChangedEvent> dataChangeController;

  setUp(() {
    mockGetTransactionsUseCase = MockGetTransactionsUseCase();
    mockDeleteExpenseUseCase = MockDeleteExpenseUseCase();
    mockDeleteIncomeUseCase = MockDeleteIncomeUseCase();
    mockApplyCategoryToBatchUseCase = MockApplyCategoryToBatchUseCase();
    mockSaveUserCategorizationHistoryUseCase =
        MockSaveUserCategorizationHistoryUseCase();
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    registerFallbackValue(GetTransactionsParams());
    registerFallbackValue(
      ApplyCategoryToBatchParams(
        transactionIds: [],
        categoryId: 'cat1',
        transactionType: TransactionType.expense,
      ),
    );
    registerFallbackValue(DeleteExpenseParams('id'));
  });

  tearDown(() {
    dataChangeController.close();
  });

  group('TransactionListBloc', () {
    final tTransaction = TransactionEntity(
      id: 'txn1',
      type: TransactionType.expense,
      title: 'Test Transaction', // Added title
      amount: 100,
      date: DateTime.now(),
      accountId: 'acc1',
    );

    test('initial state is correct', () {
      final bloc = TransactionListBloc(
        getTransactionsUseCase: mockGetTransactionsUseCase,
        deleteExpenseUseCase: mockDeleteExpenseUseCase,
        deleteIncomeUseCase: mockDeleteIncomeUseCase,
        applyCategoryToBatchUseCase: mockApplyCategoryToBatchUseCase,
        saveUserHistoryUseCase: mockSaveUserCategorizationHistoryUseCase,
        expenseRepository: mockExpenseRepository,
        incomeRepository: mockIncomeRepository,
        dataChangeStream: dataChangeController.stream,
      );
      expect(bloc.state.status, ListStatus.initial);
    });

    blocTest<TransactionListBloc, TransactionListState>(
      'ApplyBatchCategory emits success with errorMessage on failure, instead of error status',
      build: () {
        when(
          () => mockApplyCategoryToBatchUseCase(any()),
        ).thenAnswer((_) async => Left(CacheFailure('Batch update failed')));

        return TransactionListBloc(
          getTransactionsUseCase: mockGetTransactionsUseCase,
          deleteExpenseUseCase: mockDeleteExpenseUseCase,
          deleteIncomeUseCase: mockDeleteIncomeUseCase,
          applyCategoryToBatchUseCase: mockApplyCategoryToBatchUseCase,
          saveUserHistoryUseCase: mockSaveUserCategorizationHistoryUseCase,
          expenseRepository: mockExpenseRepository,
          incomeRepository: mockIncomeRepository,
          dataChangeStream: dataChangeController.stream,
        );
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [tTransaction],
        isInBatchEditMode: true,
        selectedTransactionIds: {'txn1'},
      ),
      act: (bloc) => bloc.add(ApplyBatchCategory('cat1')),
      expect: () => [
        // Loading state
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.reloading,
        ),
        // Success state with error message (Fix verification)
        isA<TransactionListState>()
            .having((s) => s.status, 'status', ListStatus.success)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('Batch update failed'),
            ),
      ],
      verify: (_) {
        verify(() => mockApplyCategoryToBatchUseCase(any())).called(1);
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'DeleteTransaction failure triggers reload instead of restoring stale state',
      build: () {
        // Mock Delete Failure
        when(
          () => mockDeleteExpenseUseCase(any()),
        ).thenAnswer((_) async => Left(CacheFailure('Delete failed')));

        // Mock Load Success (Refetching data - item still exists)
        when(
          () => mockGetTransactionsUseCase(any()),
        ).thenAnswer((_) async => Right([tTransaction]));

        return TransactionListBloc(
          getTransactionsUseCase: mockGetTransactionsUseCase,
          deleteExpenseUseCase: mockDeleteExpenseUseCase,
          deleteIncomeUseCase: mockDeleteIncomeUseCase,
          applyCategoryToBatchUseCase: mockApplyCategoryToBatchUseCase,
          saveUserHistoryUseCase: mockSaveUserCategorizationHistoryUseCase,
          expenseRepository: mockExpenseRepository,
          incomeRepository: mockIncomeRepository,
          dataChangeStream: dataChangeController.stream,
        );
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [tTransaction],
      ),
      act: (bloc) => bloc.add(DeleteTransaction(tTransaction)),
      expect: () => [
        // Optimistic Update: Item removed
        isA<TransactionListState>().having(
          (s) => s.transactions,
          'transactions',
          isEmpty,
        ),

        // Failure: Reloading status and Error Message (Triggered by failure)
        isA<TransactionListState>()
            .having((s) => s.status, 'status', ListStatus.reloading)
            .having(
              (s) => s.deleteError,
              'deleteError',
              contains('Delete failed'),
            ),

        // LoadTransactions Start: Loading (since previous status was reloading, not success)
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.loading,
        ),

        // LoadTransactions Success: Item back
        isA<TransactionListState>()
            .having((s) => s.status, 'status', ListStatus.success)
            .having((s) => s.transactions, 'transactions', hasLength(1)),
      ],
      verify: (_) {
        verify(() => mockDeleteExpenseUseCase(any())).called(1);
        verify(() => mockGetTransactionsUseCase(any())).called(1);
      },
    );
  });
}
