import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'package:expense_tracker/core/events/data_change_event.dart';

// Mocks
class MockAddExpenseUseCase extends Mock implements AddExpenseUseCase {}

class MockUpdateExpenseUseCase extends Mock implements UpdateExpenseUseCase {}

class MockAddIncomeUseCase extends Mock implements AddIncomeUseCase {}

class MockUpdateIncomeUseCase extends Mock implements UpdateIncomeUseCase {}

class MockCategorizeTransactionUseCase extends Mock
    implements CategorizeTransactionUseCase {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

// Fakes
class FakeAddExpenseParams extends Fake implements AddExpenseParams {}

class FakeUpdateExpenseParams extends Fake implements UpdateExpenseParams {}

class FakeAddIncomeParams extends Fake implements AddIncomeParams {}

class FakeUpdateIncomeParams extends Fake implements UpdateIncomeParams {}

class FakeCategorizeTransactionParams extends Fake
    implements CategorizeTransactionParams {}

void main() {
  late AddEditTransactionBloc bloc;
  late MockAddExpenseUseCase mockAddExpenseUseCase;
  late MockUpdateExpenseUseCase mockUpdateExpenseUseCase;
  late MockAddIncomeUseCase mockAddIncomeUseCase;
  late MockUpdateIncomeUseCase mockUpdateIncomeUseCase;
  late MockCategorizeTransactionUseCase mockCategorizeTransactionUseCase;
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;
  late MockCategoryRepository mockCategoryRepository;

  setUpAll(() {
    registerFallbackValue(FakeAddExpenseParams());
    registerFallbackValue(FakeUpdateExpenseParams());
    registerFallbackValue(FakeAddIncomeParams());
    registerFallbackValue(FakeUpdateIncomeParams());
    registerFallbackValue(FakeCategorizeTransactionParams());
  });

  setUp(() {
    mockAddExpenseUseCase = MockAddExpenseUseCase();
    mockUpdateExpenseUseCase = MockUpdateExpenseUseCase();
    mockAddIncomeUseCase = MockAddIncomeUseCase();
    mockUpdateIncomeUseCase = MockUpdateIncomeUseCase();
    mockCategorizeTransactionUseCase = MockCategorizeTransactionUseCase();
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    mockCategoryRepository = MockCategoryRepository();

    // Register DataChangeController in GetIt
    if (GetIt.I.isRegistered<StreamController<DataChangedEvent>>(instanceName: 'dataChangeController')) {
        GetIt.I.unregister<StreamController<DataChangedEvent>>(instanceName: 'dataChangeController');
    }
    GetIt.I.registerSingleton<StreamController<DataChangedEvent>>(
      StreamController<DataChangedEvent>.broadcast(),
      instanceName: 'dataChangeController',
    );

    bloc = AddEditTransactionBloc(
      addExpenseUseCase: mockAddExpenseUseCase,
      updateExpenseUseCase: mockUpdateExpenseUseCase,
      addIncomeUseCase: mockAddIncomeUseCase,
      updateIncomeUseCase: mockUpdateIncomeUseCase,
      categorizeTransactionUseCase: mockCategorizeTransactionUseCase,
      expenseRepository: mockExpenseRepository,
      incomeRepository: mockIncomeRepository,
      categoryRepository: mockCategoryRepository,
    );
  });

  tearDown(() {
    bloc.close();
    GetIt.I.reset();
  });

  const tCategory = Category(
    id: 'cat1',
    name: 'Food',
    iconName: 'food',
    colorHex: '#000000',
    type: CategoryType.expense,
    isCustom: false,
  );

  final tExpense = Expense(
    id: '1',
    title: 'Lunch',
    amount: 15.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
    category: tCategory,
    status: CategorizationStatus.categorized,
    confidenceScore: 1.0,
  );

  final tIncome = Income(
    id: '2',
    title: 'Salary',
    amount: 5000.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
    category: tCategory,
    status: CategorizationStatus.categorized,
    confidenceScore: 1.0,
  );

  group('InitializeTransaction', () {
    test('initializes with default state when no transaction provided', () {
      bloc.add(const InitializeTransaction());
      // The bloc emits initial state first, then processed state.
      // We check if the state *eventually* becomes ready.
      expectLater(
        bloc.stream,
        emitsThrough(
          isA<AddEditTransactionState>()
              .having((s) => s.status, 'status', AddEditStatus.ready),
        ),
      );
    });

    test('initializes with transaction data when provided', () {
      final tTransaction = TransactionEntity.fromExpense(tExpense);
      bloc.add(InitializeTransaction(initialTransaction: tTransaction));
      expectLater(
        bloc.stream,
        emits(
          isA<AddEditTransactionState>()
              .having((s) => s.transactionId, 'id', tExpense.id)
              .having((s) => s.tempTitle, 'title', tExpense.title),
        ),
      );
    });
  });

  group('TransactionTypeChanged', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'emits state with new transaction type',
      build: () => bloc,
      act:
          (bloc) => bloc.add(
            const TransactionTypeChanged(TransactionType.income),
          ),
      expect:
          () => [
            isA<AddEditTransactionState>().having(
              (s) => s.transactionType,
              'type',
              TransactionType.income,
            ),
          ],
    );
  });

  group('SaveTransactionRequested', () {
    // Expense Success
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'saves expense successfully',
      build: () {
        when(
          () => mockAddExpenseUseCase(any()),
        ).thenAnswer((_) async => Right(tExpense));
        return bloc;
      },
      seed:
          () => const AddEditTransactionState(
            tempTitle: 'Lunch',
            tempAmount: 15.0,
            tempAccountId: 'acc1',
            transactionType: TransactionType.expense,
          ),
      act:
          (bloc) => bloc.add(
            SaveTransactionRequested(
              title: 'Lunch',
              amount: 15.0,
              date: DateTime(2024, 1, 1),
              accountId: 'acc1',
              category: tCategory,
            ),
          ),
      expect:
          () => [
            isA<AddEditTransactionState>().having(
              (s) => s.status,
              'status',
              AddEditStatus.saving,
            ),
            isA<AddEditTransactionState>().having(
              (s) => s.status,
              'status',
              AddEditStatus.success,
            ),
          ],
      // Skipping initial loading state
      skip: 1,
      // Use 'wait' to allow async operations (like Future.delayed in bloc) to complete
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => mockAddExpenseUseCase(any())).called(1);
      },
    );

    // Income Success
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'saves income successfully',
      build: () {
        when(
          () => mockAddIncomeUseCase(any()),
        ).thenAnswer((_) async => Right(tIncome));
        return bloc;
      },
      seed:
          () => const AddEditTransactionState(
            tempTitle: 'Salary',
            tempAmount: 5000.0,
            tempAccountId: 'acc1',
            transactionType: TransactionType.income,
          ),
      act:
          (bloc) => bloc.add(
            SaveTransactionRequested(
              title: 'Salary',
              amount: 5000.0,
              date: DateTime(2024, 1, 1),
              accountId: 'acc1',
              category: tCategory,
            ),
          ),
      expect:
          () => [
            isA<AddEditTransactionState>().having(
              (s) => s.status,
              'status',
              AddEditStatus.saving,
            ),
            isA<AddEditTransactionState>().having(
              (s) => s.status,
              'status',
              AddEditStatus.success,
            ),
          ],
      // Skipping initial loading state
      skip: 1,
      // Use 'wait' to allow async operations (like Future.delayed in bloc) to complete
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => mockAddIncomeUseCase(any())).called(1);
      },
    );

    // Validation Failure
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'emits error when validation fails (empty title)',
      build: () => bloc,
      act:
          (bloc) => bloc.add(
            SaveTransactionRequested(
              title: '',
              amount: 15.0,
              date: DateTime(2024, 1, 1),
              accountId: 'acc1',
              category: tCategory,
            ),
          ),
      expect:
          () => [
            isA<AddEditTransactionState>()
                .having((s) => s.status, 'status', AddEditStatus.error)
                .having(
                  (s) => s.errorMessage,
                  'errorMessage',
                  'Missing required fields.',
                ),
          ],
      // Skip 1 to bypass loading
      // For validations, it seems 'loading' (or 'saving') state is emitted before error.
      // So skipping 1 is correct for [saving, error].
      // Wait, in previous runs it was [loading, saving, error] in some cases but validation aborts early.
      // Logs: "_performSave called ... Invalid data ... Aborting."
      // So it goes: loading -> saving -> error.
      // Emitted: [loading (from _onSaveTransactionRequested), error (from _performSave abort)].
      // Wait, _onSaveTransactionRequested emits loading. Then calls _performSave.
      // _performSave emits saving. Then aborts and emits error.
      // So expected sequence: loading, saving, error.
      // Actual log shows: [saving, error]. Where did loading go?
      // "Which: at location [0] is ... saving".
      // This means skip 1 removed 'loading'.
      // So we have 'saving' at index 0.
      // We expect 'error' at index 0 (because we only listed one item in expect).
      // So we should expect [saving, error] or skip 2.
      // Let's skip 2.
      skip: 2,
    );

    // Repository Failure
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'emits error when repository fails',
      build: () {
        when(
          () => mockAddExpenseUseCase(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Hive Error')));
        return bloc;
      },
      seed:
          () => const AddEditTransactionState(
            tempTitle: 'Lunch',
            tempAmount: 15.0,
            tempAccountId: 'acc1',
            transactionType: TransactionType.expense,
          ),
      act:
          (bloc) => bloc.add(
            SaveTransactionRequested(
              title: 'Lunch',
              amount: 15.0,
              date: DateTime(2024, 1, 1),
              accountId: 'acc1',
              category: tCategory,
            ),
          ),
      expect:
          () => [
            isA<AddEditTransactionState>()
                .having((s) => s.status, 'status', AddEditStatus.error)
                .having(
                  (s) => s.errorMessage,
                  'errorMessage',
                  contains('Database Error'),
                ),
          ],
      // Skip 2 to bypass loading/saving which leaves only the error state
      skip: 2,
    );
  });
}
