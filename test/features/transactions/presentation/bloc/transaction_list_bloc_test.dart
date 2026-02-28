import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
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

class MockSaveUserCategorizationHistoryUseCase extends Mock
    implements SaveUserCategorizationHistoryUseCase {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late MockGetTransactionsUseCase mockGetTransactionsUseCase;
  late MockDeleteExpenseUseCase mockDeleteExpenseUseCase;
  late MockDeleteIncomeUseCase mockDeleteIncomeUseCase;
  late MockApplyCategoryToBatchUseCase mockApplyCategoryToBatchUseCase;
  late MockSaveUserCategorizationHistoryUseCase mockSaveUserHistoryUseCase;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;
  late Stream<DataChangedEvent> dataChangeStream;

  setUp(() {
    mockGetTransactionsUseCase = MockGetTransactionsUseCase();
    mockDeleteExpenseUseCase = MockDeleteExpenseUseCase();
    mockDeleteIncomeUseCase = MockDeleteIncomeUseCase();
    mockApplyCategoryToBatchUseCase = MockApplyCategoryToBatchUseCase();
    mockSaveUserHistoryUseCase = MockSaveUserCategorizationHistoryUseCase();
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    dataChangeStream = const Stream.empty();
    registerFallbackValue(const GetTransactionsParams());
  });

  final tTxnValid = TransactionEntity(
    id: '1',
    amount: 100,
    date: DateTime.now(), // Fixed: Non-null
    type: TransactionType.expense,
    title: 'Txn',
  );

  blocTest<TransactionListBloc, TransactionListState>(
    'emits [loading, success] when LoadTransactions succeeds',
    build: () {
      when(
        () => mockGetTransactionsUseCase(any()),
      ).thenAnswer((_) async => Right([tTxnValid]));
      return TransactionListBloc(
        getTransactionsUseCase: mockGetTransactionsUseCase,
        deleteExpenseUseCase: mockDeleteExpenseUseCase,
        deleteIncomeUseCase: mockDeleteIncomeUseCase,
        applyCategoryToBatchUseCase: mockApplyCategoryToBatchUseCase,
        saveUserHistoryUseCase: mockSaveUserHistoryUseCase,
        expenseRepository: mockExpenseRepository,
        incomeRepository: mockIncomeRepository,
        dataChangeStream: dataChangeStream,
      );
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
    'updates search term and reloads',
    build: () {
      when(
        () => mockGetTransactionsUseCase(any()),
      ).thenAnswer((_) async => const Right([]));
      return TransactionListBloc(
        getTransactionsUseCase: mockGetTransactionsUseCase,
        deleteExpenseUseCase: mockDeleteExpenseUseCase,
        deleteIncomeUseCase: mockDeleteIncomeUseCase,
        applyCategoryToBatchUseCase: mockApplyCategoryToBatchUseCase,
        saveUserHistoryUseCase: mockSaveUserHistoryUseCase,
        expenseRepository: mockExpenseRepository,
        incomeRepository: mockIncomeRepository,
        dataChangeStream: dataChangeStream,
      );
    },
    act: (bloc) async {
      bloc.add(const SearchChanged(searchTerm: 'test'));
      await Future.delayed(const Duration(milliseconds: 350)); // Debounce
    },
    expect: () => [
      isA<TransactionListState>().having((s) => s.searchTerm, 'search', 'test'),
      isA<TransactionListState>().having(
        (s) => s.status,
        'status',
        ListStatus.loading,
      ), // Use ListStatus.loading as per actual result
      isA<TransactionListState>().having(
        (s) => s.status,
        'status',
        ListStatus.success,
      ),
    ],
  );
}
