import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/usecases/apply_category_to_batch.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
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

/// Covers the interactive half of the bloc: search, batch-edit selection,
/// batch categorisation, optimistic delete and manual categorisation.
///
/// These handlers are what the list screen drives on every tap, and most of
/// them mutate selection state *and* fan out to more than one use case — so the
/// tests below pin which use case is called, with what, and when one is
/// deliberately not called.
void main() {
  late TransactionListBloc bloc;
  late MockGetTransactionsUseCase getTransactions;
  late MockDeleteExpenseUseCase deleteExpense;
  late MockDeleteIncomeUseCase deleteIncome;
  late MockApplyCategoryToBatchUseCase applyBatch;
  late MockSaveUserHistoryUseCase saveHistory;
  late MockExpenseRepository expenseRepository;
  late MockIncomeRepository incomeRepository;
  late StreamController<DataChangedEvent> dataChanges;

  const groceries = Category(
    id: 'cat-groceries',
    name: 'Groceries',
    iconName: 'cart',
    colorHex: '#00FF00',
    type: CategoryType.expense,
    isCustom: false,
  );

  Expense expenseEntity({String id = 'e1'}) => Expense(
    id: id,
    title: 'Lunch',
    amount: 20,
    date: DateTime(2024, 1, 1),
    accountId: 'a1',
    status: CategorizationStatus.uncategorized,
  );

  Income incomeEntity({String id = 'i1'}) => Income(
    id: id,
    title: 'Salary',
    amount: 500,
    date: DateTime(2024, 1, 2),
    accountId: 'a1',
    status: CategorizationStatus.uncategorized,
  );

  // Built through the factories on purpose: the public constructor leaves
  // `expense`/`income` null, and the in-memory categorisation update only
  // rewrites rows that carry the original typed entity.
  final txnExpense = TransactionEntity.fromExpense(expenseEntity());
  final txnIncome = TransactionEntity.fromIncome(incomeEntity());

  setUpAll(() {
    registerFallbackValue(const GetTransactionsParams());
    registerFallbackValue(const DeleteExpenseParams('e1'));
    registerFallbackValue(const DeleteIncomeParams('i1'));
    registerFallbackValue(CategorizationStatus.categorized);
    registerFallbackValue(
      const ApplyCategoryToBatchParams(
        transactionIds: [],
        categoryId: 'c',
        transactionType: TransactionType.expense,
      ),
    );
    registerFallbackValue(
      const SaveUserCategorizationHistoryParams(
        transactionData: TransactionMatchData(description: 'd'),
        selectedCategory: groceries,
      ),
    );
  });

  setUp(() {
    getTransactions = MockGetTransactionsUseCase();
    deleteExpense = MockDeleteExpenseUseCase();
    deleteIncome = MockDeleteIncomeUseCase();
    applyBatch = MockApplyCategoryToBatchUseCase();
    saveHistory = MockSaveUserHistoryUseCase();
    expenseRepository = MockExpenseRepository();
    incomeRepository = MockIncomeRepository();
    dataChanges = StreamController<DataChangedEvent>.broadcast();

    // Reloads are chained off most handlers; default them to a quiet success.
    when(() => getTransactions(any())).thenAnswer(
      (_) async => const Right<Failure, List<TransactionEntity>>([]),
    );

    bloc = TransactionListBloc(
      getTransactionsUseCase: getTransactions,
      deleteExpenseUseCase: deleteExpense,
      deleteIncomeUseCase: deleteIncome,
      applyCategoryToBatchUseCase: applyBatch,
      saveUserHistoryUseCase: saveHistory,
      expenseRepository: expenseRepository,
      incomeRepository: incomeRepository,
      dataChangeStream: dataChanges.stream,
    );
  });

  tearDown(() async {
    await bloc.close();
    await dataChanges.close();
  });

  group('SearchChanged', () {
    // The handler sits behind a 300ms debounce, so every test here has to
    // outlast that window or the bloc closes before the handler ever runs.
    const pastDebounce = Duration(milliseconds: 400);

    blocTest<TransactionListBloc, TransactionListState>(
      'stores the term, leaves batch mode and drops the selection',
      build: () => bloc,
      seed: () => const TransactionListState(
        isInBatchEditMode: true,
        selectedTransactionIds: {'e1'},
      ),
      act: (b) => b.add(const SearchChanged(searchTerm: 'coffee')),
      wait: pastDebounce,
      expect: () => [
        isA<TransactionListState>()
            .having((s) => s.searchTerm, 'searchTerm', 'coffee')
            .having((s) => s.isInBatchEditMode, 'batchMode', false)
            .having((s) => s.selectedTransactionIds, 'selection', isEmpty),
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
      verify: (_) {
        // The point of the reload: the term must reach the query, not just
        // sit in the state.
        final params =
            verify(() => getTransactions(captureAny())).captured.last
                as GetTransactionsParams;
        expect(params.searchTerm, 'coffee');
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'an empty term clears the search rather than querying for ""',
      build: () => bloc,
      seed: () => const TransactionListState(searchTerm: 'coffee'),
      act: (b) => b.add(const SearchChanged(searchTerm: '')),
      wait: pastDebounce,
      verify: (_) {
        final params =
            verify(() => getTransactions(captureAny())).captured.last
                as GetTransactionsParams;
        expect(params.searchTerm, isNull);
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'keystrokes inside the debounce window collapse to one query',
      build: () => bloc,
      // Spaced deliberately: 100ms apart is faster than the 300ms window but
      // slower than a synchronous burst, which any non-zero debounce would
      // collapse. Only a window longer than the gap merges these three.
      act: (b) async {
        b.add(const SearchChanged(searchTerm: 'c'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        b.add(const SearchChanged(searchTerm: 'co'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        b.add(const SearchChanged(searchTerm: 'cof'));
      },
      wait: pastDebounce,
      verify: (_) {
        final params = verify(
          () => getTransactions(captureAny()),
        ).captured.cast<GetTransactionsParams>();
        expect(params, hasLength(1));
        expect(params.single.searchTerm, 'cof');
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'a pause longer than the window starts a second query',
      build: () => bloc,
      act: (b) async {
        b.add(const SearchChanged(searchTerm: 'tea'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
        b.add(const SearchChanged(searchTerm: 'coffee'));
      },
      wait: pastDebounce,
      verify: (_) {
        final params = verify(
          () => getTransactions(captureAny()),
        ).captured.cast<GetTransactionsParams>();
        expect(params.map((p) => p.searchTerm), ['tea', 'coffee']);
      },
    );
  });

  group('ToggleBatchEdit', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'turns batch mode on',
      build: () => bloc,
      act: (b) => b.add(const ToggleBatchEdit()),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.isInBatchEditMode,
          'batchMode',
          true,
        ),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'turning it off discards the selection',
      build: () => bloc,
      seed: () => const TransactionListState(
        isInBatchEditMode: true,
        selectedTransactionIds: {'e1', 'i1'},
      ),
      act: (b) => b.add(const ToggleBatchEdit()),
      expect: () => [
        isA<TransactionListState>()
            .having((s) => s.isInBatchEditMode, 'batchMode', false)
            .having((s) => s.selectedTransactionIds, 'selection', isEmpty),
      ],
    );
  });

  group('SelectTransaction', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'is ignored outside batch mode',
      build: () => bloc,
      act: (b) => b.add(const SelectTransaction('e1')),
      expect: () => const <TransactionListState>[],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'adds then removes the same id on a second tap',
      build: () => bloc,
      seed: () => const TransactionListState(isInBatchEditMode: true),
      act: (b) => b
        ..add(const SelectTransaction('e1'))
        ..add(const SelectTransaction('i1'))
        ..add(const SelectTransaction('e1')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.selectedTransactionIds,
          'selection',
          {'e1'},
        ),
        isA<TransactionListState>().having(
          (s) => s.selectedTransactionIds,
          'selection',
          {'e1', 'i1'},
        ),
        isA<TransactionListState>().having(
          (s) => s.selectedTransactionIds,
          'selection',
          {'i1'},
        ),
      ],
    );
  });

  group('ApplyBatchCategory', () {
    TransactionListState batchState({Set<String> selection = const {'e1'}}) =>
        TransactionListState(
          status: ListStatus.success,
          transactions: [txnExpense, txnIncome],
          isInBatchEditMode: true,
          selectedTransactionIds: selection,
        );

    blocTest<TransactionListBloc, TransactionListState>(
      'is ignored when nothing is selected',
      build: () => bloc,
      seed: () => const TransactionListState(isInBatchEditMode: true),
      act: (b) => b.add(const ApplyBatchCategory('cat-groceries')),
      expect: () => const <TransactionListState>[],
      verify: (_) => verifyNever(() => applyBatch(any())),
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'is ignored outside batch mode even with a selection',
      build: () => bloc,
      seed: () => const TransactionListState(selectedTransactionIds: {'e1'}),
      act: (b) => b.add(const ApplyBatchCategory('cat-groceries')),
      expect: () => const <TransactionListState>[],
      verify: (_) => verifyNever(() => applyBatch(any())),
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'splits the selection into one expense call and one income call',
      build: () {
        when(
          () => applyBatch(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        return bloc;
      },
      seed: () => batchState(selection: {'e1', 'i1'}),
      act: (b) => b.add(const ApplyBatchCategory('cat-groceries')),
      verify: (_) {
        final calls = verify(
          () => applyBatch(captureAny()),
        ).captured.cast<ApplyCategoryToBatchParams>();
        expect(calls, hasLength(2));
        final expenseCall = calls.singleWhere(
          (p) => p.transactionType == TransactionType.expense,
        );
        final incomeCall = calls.singleWhere(
          (p) => p.transactionType == TransactionType.income,
        );
        // Each call must carry only the ids of its own type.
        expect(expenseCall.transactionIds, ['e1']);
        expect(incomeCall.transactionIds, ['i1']);
        expect(expenseCall.categoryId, 'cat-groceries');
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'a selected id that is no longer in the list is skipped',
      build: () {
        when(
          () => applyBatch(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        return bloc;
      },
      seed: () => batchState(selection: {'e1', 'ghost'}),
      act: (b) => b.add(const ApplyBatchCategory('cat-groceries')),
      verify: (_) {
        final calls = verify(
          () => applyBatch(captureAny()),
        ).captured.cast<ApplyCategoryToBatchParams>();
        // Only the expense call — the unknown id contributes nothing.
        expect(calls, hasLength(1));
        expect(calls.single.transactionIds, ['e1']);
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'leaves batch mode and reloads on success',
      build: () {
        when(
          () => applyBatch(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        return bloc;
      },
      seed: () => batchState(),
      act: (b) => b.add(const ApplyBatchCategory('cat-groceries')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.reloading,
        ),
        isA<TransactionListState>()
            .having((s) => s.isInBatchEditMode, 'batchMode', false)
            .having((s) => s.selectedTransactionIds, 'selection', isEmpty),
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
      verify: (_) => verify(() => getTransactions(any())).called(1),
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'an expense failure short-circuits the income call and keeps the list',
      build: () {
        when(() => applyBatch(any())).thenAnswer(
          (_) async => const Left<Failure, void>(CacheFailure('box closed')),
        );
        return bloc;
      },
      seed: () => batchState(selection: {'e1', 'i1'}),
      act: (b) => b.add(const ApplyBatchCategory('cat-groceries')),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.status,
          'status',
          ListStatus.reloading,
        ),
        isA<TransactionListState>()
            // The list stays visible; only an error banner is added.
            .having((s) => s.status, 'status', ListStatus.success)
            .having(
              (s) => s.errorMessage,
              'error',
              contains('Failed batch category update'),
            )
            .having((s) => s.transactions, 'transactions', hasLength(2)),
      ],
      verify: (_) {
        // Exactly one call: the income half must not run after the expense
        // half failed.
        final calls = verify(
          () => applyBatch(captureAny()),
        ).captured.cast<ApplyCategoryToBatchParams>();
        expect(calls, hasLength(1));
        expect(calls.single.transactionType, TransactionType.expense);
        verifyNever(() => getTransactions(any()));
      },
    );
  });

  group('DeleteTransaction', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'removes the row immediately and keeps it gone when the delete succeeds',
      build: () {
        when(
          () => deleteExpense(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        return bloc;
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [txnExpense, txnIncome],
        selectedTransactionIds: const {'e1'},
      ),
      act: (b) => b.add(DeleteTransaction(txnExpense)),
      expect: () => [
        isA<TransactionListState>()
            .having((s) => s.transactions.map((t) => t.id), 'ids', ['i1'])
            // The deleted row must also leave the selection.
            .having((s) => s.selectedTransactionIds, 'selection', isEmpty),
      ],
      verify: (_) => verifyNever(() => deleteIncome(any())),
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'routes an income row to the income use case',
      build: () {
        when(
          () => deleteIncome(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        return bloc;
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [txnExpense, txnIncome],
      ),
      act: (b) => b.add(DeleteTransaction(txnIncome)),
      verify: (_) {
        verify(() => deleteIncome(any())).called(1);
        verifyNever(() => deleteExpense(any()));
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'surfaces a delete failure and reloads instead of restoring the row',
      build: () {
        when(() => deleteExpense(any())).thenAnswer(
          (_) async => const Left<Failure, void>(CacheFailure('locked')),
        );
        return bloc;
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [txnExpense, txnIncome],
      ),
      act: (b) => b.add(DeleteTransaction(txnExpense)),
      expect: () => [
        // Optimistic removal happens first, regardless of the outcome.
        isA<TransactionListState>().having(
          (s) => s.transactions.map((t) => t.id),
          'ids',
          ['i1'],
        ),
        isA<TransactionListState>()
            .having((s) => s.deleteError, 'deleteError', contains('delete'))
            .having((s) => s.status, 'status', ListStatus.reloading),
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
      // The reload is what repairs the optimistic removal.
      verify: (_) => verify(() => getTransactions(any())).called(1),
    );
  });

  group('UserCategorizedTransaction', () {
    UserCategorizedTransaction event({
      String id = 'e1',
      TransactionType type = TransactionType.expense,
    }) => UserCategorizedTransaction(
      transactionId: id,
      transactionType: type,
      selectedCategory: groceries,
      matchData: const TransactionMatchData(description: 'Lunch'),
    );

    setUp(() {
      when(
        () => saveHistory(any()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));
    });

    blocTest<TransactionListBloc, TransactionListState>(
      'writes the category onto the expense row in place',
      build: () {
        when(
          () => expenseRepository.updateExpenseCategorization(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        return bloc;
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [txnExpense, txnIncome],
      ),
      act: (b) => b.add(event()),
      expect: () => [
        isA<TransactionListState>()
            .having(
              (s) => s.transactions.firstWhere((t) => t.id == 'e1').category,
              'category',
              groceries,
            )
            .having(
              (s) => s.transactions.firstWhere((t) => t.id == 'e1').status,
              'status',
              CategorizationStatus.categorized,
            )
            .having(
              (s) => s.transactions
                  .firstWhere((t) => t.id == 'e1')
                  .confidenceScore,
              'confidence',
              1.0,
            )
            // The untouched row must survive the rewrite unchanged.
            .having(
              (s) => s.transactions.firstWhere((t) => t.id == 'i1').category,
              'other row category',
              isNull,
            ),
      ],
      verify: (_) {
        verify(
          () => expenseRepository.updateExpenseCategorization(
            'e1',
            'cat-groceries',
            CategorizationStatus.categorized,
            1.0,
          ),
        ).called(1);
        verify(() => saveHistory(any())).called(1);
      },
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'writes the category onto the income row in place',
      build: () {
        when(
          () => incomeRepository.updateIncomeCategorization(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        return bloc;
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [txnExpense, txnIncome],
      ),
      act: (b) => b.add(event(id: 'i1', type: TransactionType.income)),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.transactions.firstWhere((t) => t.id == 'i1').category,
          'category',
          groceries,
        ),
      ],
      verify: (_) => verifyNever(
        () => expenseRepository.updateExpenseCategorization(
          any(),
          any(),
          any(),
          any(),
        ),
      ),
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'reports a repository failure and leaves the row uncategorized',
      build: () {
        when(
          () => expenseRepository.updateExpenseCategorization(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer(
          (_) async => const Left<Failure, void>(CacheFailure('write failed')),
        );
        return bloc;
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [txnExpense],
      ),
      act: (b) => b.add(event()),
      expect: () => [
        isA<TransactionListState>()
            .having((s) => s.status, 'status', ListStatus.error)
            .having(
              (s) => s.errorMessage,
              'error',
              contains('Failed to update category'),
            )
            .having((s) => s.transactions.single.category, 'category', isNull),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'a failing history write does not block the categorisation',
      build: () {
        // History is fire-and-forget; a rejected future must not surface.
        when(
          () => saveHistory(any()),
        ).thenAnswer((_) async => throw Exception('history box closed'));
        when(
          () => expenseRepository.updateExpenseCategorization(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => const Right<Failure, void>(null));
        return bloc;
      },
      seed: () => TransactionListState(
        status: ListStatus.success,
        transactions: [txnExpense],
      ),
      act: (b) => b.add(event()),
      expect: () => [
        isA<TransactionListState>().having(
          (s) => s.transactions.single.category,
          'category',
          groceries,
        ),
      ],
    );
  });
}
