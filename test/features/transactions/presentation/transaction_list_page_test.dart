import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_expense_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_income_categories.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class MockGetExpenseCategoriesUseCase extends Mock
    implements GetExpenseCategoriesUseCase {}

class MockGetIncomeCategoriesUseCase extends Mock
    implements GetIncomeCategoriesUseCase {}

class FakeTransactionListEvent extends Fake implements TransactionListEvent {}

class FakeTransactionListState extends Fake implements TransactionListState {}

class FakeSettingsEvent extends Fake implements SettingsEvent {}

class FakeSettingsState extends Fake implements SettingsState {}

class FakeAccountListEvent extends Fake implements AccountListEvent {}

class FakeAccountListState extends Fake implements AccountListState {}

class FakeCategoryManagementEvent extends Fake
    implements CategoryManagementEvent {}

class FakeCategoryManagementState extends Fake
    implements CategoryManagementState {}

Future<void> provideMockSvg() async {
  const svgString =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"></svg>';
  final data = ByteData.view(Uint8List.fromList(svgString.codeUnits).buffer);
  ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async => data,
  );
}

const categoryFood = Category(
  id: 'c1',
  name: 'Food',
  iconName: 'food',
  colorHex: '#FF0000',
  type: CategoryType.expense,
  isCustom: false,
);

const categoryTravel = Category(
  id: 'c2',
  name: 'Travel',
  iconName: 'travel',
  colorHex: '#00FF00',
  type: CategoryType.expense,
  isCustom: false,
);

final expense1 = Expense(
  id: 't1',
  title: 'Pizza',
  amount: 10,
  date: DateTime(2024, 1, 1),
  category: categoryFood,
  accountId: 'a1',
  status: CategorizationStatus.categorized,
);

final expense2 = Expense(
  id: 't2',
  title: 'Bus',
  amount: 5,
  date: DateTime(2024, 1, 2),
  category: categoryTravel,
  accountId: 'a2',
  status: CategorizationStatus.categorized,
);

final txn1 = Transaction.fromExpense(expense1);
final txn2 = Transaction.fromExpense(expense2);

final account1 = AssetAccount(
  id: 'a1',
  name: 'Checking',
  type: AssetType.bank,
  currentBalance: 1000,
);

final account2 = AssetAccount(
  id: 'a2',
  name: 'Cash',
  type: AssetType.cash,
  currentBalance: 500,
);

const settingsState = SettingsState(
  status: SettingsStatus.loaded,
  uiMode: UIMode.elemental,
);

Widget buildPage(
  TransactionListBloc transactionBloc,
  SettingsBloc settingsBloc,
  AccountListBloc accountBloc,
  CategoryManagementBloc categoryBloc,
) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<TransactionListBloc>.value(value: transactionBloc),
      BlocProvider<SettingsBloc>.value(value: settingsBloc),
      BlocProvider<AccountListBloc>.value(value: accountBloc),
      BlocProvider<CategoryManagementBloc>.value(value: categoryBloc),
    ],
    child: const TransactionListPage(),
  );
}

Widget buildAppWithRouter(
  TransactionListBloc transactionBloc,
  SettingsBloc settingsBloc,
  AccountListBloc accountBloc,
  CategoryManagementBloc categoryBloc,
) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            buildPage(transactionBloc, settingsBloc, accountBloc, categoryBloc),
        routes: [
          GoRoute(
            name: RouteNames.editTransaction,
            path: 'edit/:${RouteNames.paramTransactionId}',
            builder: (context, state) =>
                const Scaffold(body: Text('detail-page')),
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(FakeTransactionListEvent());
    registerFallbackValue(FakeTransactionListState());
    registerFallbackValue(FakeSettingsEvent());
    registerFallbackValue(FakeSettingsState());
    registerFallbackValue(FakeAccountListEvent());
    registerFallbackValue(FakeAccountListState());
    registerFallbackValue(FakeCategoryManagementEvent());
    registerFallbackValue(FakeCategoryManagementState());
    registerFallbackValue(NoParams());
    provideMockSvg();
  });

  testWidgets(
    'initially shows loading then displays transactions when success state is emitted',
    (tester) async {
      final transactionBloc = MockTransactionListBloc();
      final settingsBloc = MockSettingsBloc();
      final accountBloc = MockAccountListBloc();
      final categoryBloc = MockCategoryManagementBloc();

      final controller = StreamController<TransactionListState>();
      const loadingState = TransactionListState(status: ListStatus.loading);
      whenListen(
        transactionBloc,
        controller.stream,
        initialState: loadingState,
      );
      when(() => transactionBloc.state).thenReturn(loadingState);

      when(() => settingsBloc.state).thenReturn(settingsState);
      final accountsState = AccountListLoaded(accounts: [account1, account2], liabilities: []);
      when(() => accountBloc.state).thenReturn(accountsState);
      whenListen(
        accountBloc,
        Stream<AccountListState>.empty(),
        initialState: accountsState,
      );
      const catState = CategoryManagementState(
        status: CategoryManagementStatus.loaded,
        predefinedExpenseCategories: [categoryFood, categoryTravel],
      );
      when(() => categoryBloc.state).thenReturn(catState);
      whenListen(
        categoryBloc,
        Stream<CategoryManagementState>.empty(),
        initialState: catState,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: buildPage(
            transactionBloc,
            settingsBloc,
            accountBloc,
            categoryBloc,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.add(
        TransactionListState(
          status: ListStatus.success,
          transactions: [txn1, txn2],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionListView), findsOneWidget);
      expect(find.byType(ExpenseCard), findsNWidgets(2));
      await controller.close();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('shows empty state message when no transactions', (tester) async {
    final transactionBloc = MockTransactionListBloc();
    final settingsBloc = MockSettingsBloc();
    final accountBloc = MockAccountListBloc();
    final categoryBloc = MockCategoryManagementBloc();

    const emptyState = TransactionListState(
      status: ListStatus.success,
      transactions: [],
    );
    whenListen(
      transactionBloc,
      Stream.value(emptyState),
      initialState: emptyState,
    );
    when(() => transactionBloc.state).thenReturn(emptyState);

    when(() => settingsBloc.state).thenReturn(settingsState);
    final accountsState = AccountListLoaded(accounts: [account1, account2], liabilities: []);
    when(() => accountBloc.state).thenReturn(accountsState);
    whenListen(
      accountBloc,
      Stream<AccountListState>.empty(),
      initialState: accountsState,
    );
    const catState = CategoryManagementState(
      status: CategoryManagementStatus.loaded,
      predefinedExpenseCategories: [categoryFood, categoryTravel],
    );
    when(() => categoryBloc.state).thenReturn(catState);
    whenListen(
      categoryBloc,
      Stream<CategoryManagementState>.empty(),
      initialState: catState,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: buildPage(
          transactionBloc,
          settingsBloc,
          accountBloc,
          categoryBloc,
        ),
      ),
    );

    expect(find.text('No transactions recorded yet'), findsOneWidget);
  });

  testWidgets('shows error message when bloc is in error state', (
    tester,
  ) async {
    final transactionBloc = MockTransactionListBloc();
    final settingsBloc = MockSettingsBloc();
    final accountBloc = MockAccountListBloc();
    final categoryBloc = MockCategoryManagementBloc();

    const errorState = TransactionListState(
      status: ListStatus.error,
      transactions: [],
      errorMessage: 'boom',
    );
    whenListen(
      transactionBloc,
      Stream.value(errorState),
      initialState: errorState,
    );
    when(() => transactionBloc.state).thenReturn(errorState);

    when(() => settingsBloc.state).thenReturn(settingsState);
    final accountsState = AccountListLoaded(accounts: [account1, account2], liabilities: []);
    when(() => accountBloc.state).thenReturn(accountsState);
    whenListen(
      accountBloc,
      Stream<AccountListState>.empty(),
      initialState: accountsState,
    );
    const catState = CategoryManagementState(
      status: CategoryManagementStatus.loaded,
    );
    when(() => categoryBloc.state).thenReturn(catState);
    whenListen(
      categoryBloc,
      Stream<CategoryManagementState>.empty(),
      initialState: catState,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: buildPage(
          transactionBloc,
          settingsBloc,
          accountBloc,
          categoryBloc,
        ),
      ),
    );

    expect(find.text('Error: boom'), findsOneWidget);
  });

  testWidgets('filters transactions by account', (tester) async {
    final transactionBloc = MockTransactionListBloc();
    final settingsBloc = MockSettingsBloc();
    final accountBloc = MockAccountListBloc();
    final categoryBloc = MockCategoryManagementBloc();

    final controller = StreamController<TransactionListState>();
    final initialState = TransactionListState(
      status: ListStatus.success,
      transactions: [txn1, txn2],
    );
    whenListen(transactionBloc, controller.stream, initialState: initialState);
    when(() => transactionBloc.state).thenReturn(initialState);

    when(() => settingsBloc.state).thenReturn(settingsState);
    final accountsState = AccountListLoaded(accounts: [account1, account2], liabilities: []);
    when(() => accountBloc.state).thenReturn(accountsState);
    whenListen(
      accountBloc,
      Stream<AccountListState>.empty(),
      initialState: accountsState,
    );
    const catState = CategoryManagementState(
      status: CategoryManagementStatus.loaded,
    );
    when(() => categoryBloc.state).thenReturn(catState);
    whenListen(
      categoryBloc,
      Stream<CategoryManagementState>.empty(),
      initialState: catState,
    );

    final mockGetCategories = MockGetCategoriesUseCase();
    when(
      () => mockGetCategories.call(any()),
    ).thenAnswer((_) async => const Right([categoryFood, categoryTravel]));
    sl.registerSingleton<GetCategoriesUseCase>(mockGetCategories);
    addTearDown(() => sl.unregister<GetCategoriesUseCase>());

    await tester.pumpWidget(
      MaterialApp(
        home: buildPage(
          transactionBloc,
          settingsBloc,
          accountBloc,
          categoryBloc,
        ),
      ),
    );

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AccountSelectorDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checking').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Apply Filters'));
    await tester.pumpAndSettle();

    verify(
      () => transactionBloc.add(
        any(
          that: isA<FilterChanged>().having(
            (e) => e.accountId,
            'accountId',
            account1.id,
          ),
        ),
      ),
    ).called(1);

    controller.add(
      initialState.copyWith(transactions: [txn1], accountId: account1.id),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseCard), findsOneWidget);
    await controller.close();
    await tester.pumpAndSettle();
  });

  testWidgets('batch categorization flow applies category and exits mode', (
    tester,
  ) async {
    final transactionBloc = MockTransactionListBloc();
    final settingsBloc = MockSettingsBloc();
    final accountBloc = MockAccountListBloc();
    final categoryBloc = MockCategoryManagementBloc();

    final controller = StreamController<TransactionListState>();
    final initialState = TransactionListState(
      status: ListStatus.success,
      transactions: [txn1, txn2],
    );
    whenListen(transactionBloc, controller.stream, initialState: initialState);
    when(() => transactionBloc.state).thenReturn(initialState);

    when(() => settingsBloc.state).thenReturn(settingsState);
    final accountsState = AccountListLoaded(accounts: [account1, account2], liabilities: []);
    when(() => accountBloc.state).thenReturn(accountsState);
    whenListen(
      accountBloc,
      Stream<AccountListState>.empty(),
      initialState: accountsState,
    );
    const catState = CategoryManagementState(
      status: CategoryManagementStatus.loaded,
    );
    when(() => categoryBloc.state).thenReturn(catState);
    whenListen(
      categoryBloc,
      Stream<CategoryManagementState>.empty(),
      initialState: catState,
    );

    final mockGetExpenseCats = MockGetExpenseCategoriesUseCase();
    when(
      () => mockGetExpenseCats.call(any()),
    ).thenAnswer((_) async => const Right([categoryFood, categoryTravel]));
    final mockGetIncomeCats = MockGetIncomeCategoriesUseCase();
    when(
      () => mockGetIncomeCats.call(any()),
    ).thenAnswer((_) async => const Right([]));
    sl.registerSingleton<GetExpenseCategoriesUseCase>(mockGetExpenseCats);
    sl.registerSingleton<GetIncomeCategoriesUseCase>(mockGetIncomeCats);
    addTearDown(() {
      if (sl.isRegistered<GetExpenseCategoriesUseCase>()) {
        sl.unregister<GetExpenseCategoriesUseCase>();
      }
      if (sl.isRegistered<GetIncomeCategoriesUseCase>()) {
        sl.unregister<GetIncomeCategoriesUseCase>();
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: buildPage(
          transactionBloc,
          settingsBloc,
          accountBloc,
          categoryBloc,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.select_all_rounded));
    await tester.pumpAndSettle();

    verify(() => transactionBloc.add(const ToggleBatchEdit())).called(1);

    controller.add(initialState.copyWith(isInBatchEditMode: true));
    await tester.pumpAndSettle();

    final fabFinder = find.byKey(const ValueKey('batch_fab'));
    final FloatingActionButton fab = tester.widget(fabFinder);
    expect(fab.onPressed, isNull);

    await tester.tap(find.byType(ExpenseCard).at(0));
    await tester.pumpAndSettle();
    verify(
      () => transactionBloc.add(
        any(
          that: isA<SelectTransaction>().having(
            (e) => e.transactionId,
            'transactionId',
            't1',
          ),
        ),
      ),
    ).called(1);
    controller.add(
      initialState.copyWith(
        isInBatchEditMode: true,
        selectedTransactionIds: {'t1'},
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FloatingActionButton, 'Categorize (1)'),
      findsOneWidget,
    );

    await tester.tap(find.byType(ExpenseCard).at(1));
    await tester.pumpAndSettle();
    verify(
      () => transactionBloc.add(
        any(
          that: isA<SelectTransaction>().having(
            (e) => e.transactionId,
            'transactionId',
            't2',
          ),
        ),
      ),
    ).called(1);
    controller.add(
      initialState.copyWith(
        isInBatchEditMode: true,
        selectedTransactionIds: {'t1', 't2'},
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FloatingActionButton, 'Categorize (2)'),
      findsOneWidget,
    );

    await tester.tap(fabFinder);
    await tester.pumpAndSettle();
    expect(find.text('Select Expense Category'), findsOneWidget);
    await tester.tap(find.text('Travel').first);
    await tester.pumpAndSettle();

    controller.add(
      initialState.copyWith(
        isInBatchEditMode: false,
        selectedTransactionIds: {},
      ),
    );
    await tester.pumpAndSettle();
    final animatedFab = tester.widget<AnimatedScale>(
      find.ancestor(of: fabFinder, matching: find.byType(AnimatedScale)),
    );
    expect(animatedFab.scale, 0);
    await controller.close();
    await tester.pumpAndSettle();
  });

  testWidgets('tapping card selects in batch mode', (tester) async {
    final transactionBloc = MockTransactionListBloc();
    final settingsBloc = MockSettingsBloc();
    final accountBloc = MockAccountListBloc();
    final categoryBloc = MockCategoryManagementBloc();

    final state = TransactionListState(
      status: ListStatus.success,
      transactions: [txn1],
      isInBatchEditMode: true,
    );
    whenListen(transactionBloc, Stream.value(state), initialState: state);
    when(() => transactionBloc.state).thenReturn(state);

    when(() => settingsBloc.state).thenReturn(settingsState);
    final accountsState = AccountListLoaded(accounts: [account1], liabilities: []);
    when(() => accountBloc.state).thenReturn(accountsState);
    whenListen(
      accountBloc,
      Stream<AccountListState>.empty(),
      initialState: accountsState,
    );
    const catState = CategoryManagementState(
      status: CategoryManagementStatus.loaded,
    );
    when(() => categoryBloc.state).thenReturn(catState);
    whenListen(
      categoryBloc,
      Stream<CategoryManagementState>.empty(),
      initialState: catState,
    );

    await tester.pumpWidget(
      buildAppWithRouter(
        transactionBloc,
        settingsBloc,
        accountBloc,
        categoryBloc,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ExpenseCard));
    verify(() => transactionBloc.add(SelectTransaction('t1'))).called(1);
    expect(find.text('detail-page'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('tapping card navigates in normal mode', (tester) async {
    final transactionBloc = MockTransactionListBloc();
    final settingsBloc = MockSettingsBloc();
    final accountBloc = MockAccountListBloc();
    final categoryBloc = MockCategoryManagementBloc();

    final state = TransactionListState(
      status: ListStatus.success,
      transactions: [txn1],
    );
    whenListen(transactionBloc, Stream.value(state), initialState: state);
    when(() => transactionBloc.state).thenReturn(state);

    when(() => settingsBloc.state).thenReturn(settingsState);
    final accountsState = AccountListLoaded(accounts: [account1], liabilities: []);
    when(() => accountBloc.state).thenReturn(accountsState);
    whenListen(
      accountBloc,
      Stream<AccountListState>.empty(),
      initialState: accountsState,
    );
    const catState = CategoryManagementState(
      status: CategoryManagementStatus.loaded,
    );
    when(() => categoryBloc.state).thenReturn(catState);
    whenListen(
      categoryBloc,
      Stream<CategoryManagementState>.empty(),
      initialState: catState,
    );

    await tester.pumpWidget(
      buildAppWithRouter(
        transactionBloc,
        settingsBloc,
        accountBloc,
        categoryBloc,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ExpenseCard));
    await tester.pumpAndSettle();
    expect(find.text('detail-page'), findsOneWidget);
    verifyNever(() => transactionBloc.add(any(that: isA<SelectTransaction>())));
    await tester.pumpAndSettle();
  });

  group('getDominantTransactionType', () {
    test('returns null when selected IDs contain a stale entry', () {
      final expense = Expense(
        id: '1',
        title: 'Lunch',
        amount: 10.0,
        date: DateTime(2024, 1, 1),
        category: Category.uncategorized,
        accountId: 'acc1',
      );

      final state = TransactionListState(
        transactions: [Transaction.fromExpense(expense)],
        selectedTransactionIds: const {'1', 'stale-id'},
      );

      final result = getDominantTransactionTypeForTesting(state);

      expect(result, isNull);
    });
  });
}
