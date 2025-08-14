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
import 'package:table_calendar/table_calendar.dart';

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

  group('TransactionListBloc view toggling', () {
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
      'toggles calendar view flag',
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
      act: (bloc) => bloc.add(const ToggleCalendarView()),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.isCalendarViewVisible,
          'calendar',
          true,
        ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'updates selected and focused day',
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
      act: (bloc) {
        final day = DateTime(2024, 1, 2);
        bloc.add(CalendarDaySelected(selectedDay: day, focusedDay: day));
      },
      expect: () => [
        isA<TransactionListState>()
            .having((s) => s.selectedDay, 'selectedDay', DateTime(2024, 1, 2))
            .having((s) => s.focusedDay, 'focusedDay', DateTime(2024, 1, 2)),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'changes calendar format',
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
      act: (bloc) => bloc.add(const CalendarFormatChanged(CalendarFormat.week)),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.calendarFormat,
          'format',
          CalendarFormat.week,
        ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'changes focused day',
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
      act: (bloc) {
        final day = DateTime(2024, 5, 10);
        bloc.add(CalendarPageChanged(day));
      },
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.focusedDay,
          'focusedDay',
          DateTime(2024, 5, 10),
        ),
      ],
    );
  });
}
