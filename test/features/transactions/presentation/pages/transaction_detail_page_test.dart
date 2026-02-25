import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late TransactionListBloc mockTransactionListBloc;
  late AccountListBloc mockAccountListBloc;
  late MockGoRouter mockGoRouter;

  setUpAll(() {});

  setUp(() {
    mockTransactionListBloc = MockTransactionListBloc();
    mockAccountListBloc = MockAccountListBloc();
    mockGoRouter = MockGoRouter();
  });

  final mockTransaction = TransactionEntity(
    id: '1',
    title: 'Coffee',
    amount: 4.50,
    date: DateTime(2023, 1, 1),
    category: const Category(
      id: 'cat1',
      name: 'Food',
      iconName: 'food',
      colorHex: '#ffff00',
      type: CategoryType.expense,
      isCustom: true,
    ),
    accountId: 'acc1',
    type: TransactionType.expense,
    notes: 'Morning coffee',
  );

  final mockAccount = AssetAccount(
    id: 'acc1',
    name: 'Main Bank',
    type: AssetType.bank,
    initialBalance: 1000,
    currentBalance: 1000,
  );

  Widget buildTestWidget({TransactionEntity? transaction}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionListBloc>.value(value: mockTransactionListBloc),
        BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
      ],
      child: TransactionDetailPage(
        transactionId: '1',
        transaction: transaction,
      ),
    );
  }

  group('TransactionDetailPage', () {
    testWidgets('renders all transaction details correctly when provided', (
      tester,
    ) async {
      // ARRANGE
      when(
        () => mockAccountListBloc.state,
      ).thenReturn(AccountListLoaded(accounts: [mockAccount]));
      when(
        () => mockTransactionListBloc.state,
      ).thenReturn(const TransactionListState());

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(transaction: mockTransaction),
      );

      // ASSERT
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('- \$4.50'), findsOneWidget);
      expect(find.text('Jan 1, 2023 12:00 AM'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Main Bank'), findsOneWidget);
      expect(find.text('Morning coffee'), findsOneWidget);
    });

    testWidgets(
      'fetches transaction from Bloc when not provided (deep link scenario)',
      (tester) async {
        // ARRANGE
        when(
          () => mockAccountListBloc.state,
        ).thenReturn(AccountListLoaded(accounts: [mockAccount]));

        // Simulate state with transaction loaded
        when(() => mockTransactionListBloc.state).thenReturn(
          TransactionListState(
            status: ListStatus.success,
            transactions: [mockTransaction],
          ),
        );

        // ACT - Pass null transaction
        await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(transaction: null),
        );

        // ASSERT - Should find details because it looked up ID '1' in the Bloc state
        expect(find.text('Coffee'), findsOneWidget);
        expect(find.text('- \$4.50'), findsOneWidget);
      },
    );

    testWidgets('shows Not Found when transaction is missing in Bloc', (
      tester,
    ) async {
      // ARRANGE
      when(
        () => mockAccountListBloc.state,
      ).thenReturn(const AccountListInitial());
      when(() => mockTransactionListBloc.state).thenReturn(
        const TransactionListState(
          status: ListStatus.success,
          transactions: [],
        ),
      );

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(transaction: null),
      );

      // ASSERT
      expect(find.text('Not Found'), findsOneWidget);
      expect(find.text('Transaction not found or deleted.'), findsOneWidget);
    });

    testWidgets('shows Loading when Bloc is loading', (tester) async {
      // ARRANGE
      when(
        () => mockAccountListBloc.state,
      ).thenReturn(const AccountListInitial());
      when(
        () => mockTransactionListBloc.state,
      ).thenReturn(const TransactionListState(status: ListStatus.loading));

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(transaction: null),
        settle: false,
      );
      await tester.pump();

      // ASSERT
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping Edit button does not throw', (tester) async {
      when(
        () => mockAccountListBloc.state,
      ).thenReturn(const AccountListInitial());
      when(
        () => mockTransactionListBloc.state,
      ).thenReturn(const TransactionListState());

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => buildTestWidget(transaction: mockTransaction),
          ),
          GoRoute(
            path: '/edit/:transactionId',
            name: RouteNames.editTransaction,
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ],
      );

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SizedBox.shrink(),
        router: router,
      );

      final editFinder = find.byKey(
        const ValueKey('button_transactionDetail_edit'),
      );
      expect(editFinder, findsOneWidget);
      await tester.tap(editFinder);
      await tester.pump();
    });

    testWidgets('tapping Delete button shows dialog and dispatches event', (
      tester,
    ) async {
      // ARRANGE
      when(
        () => mockAccountListBloc.state,
      ).thenReturn(const AccountListInitial());
      when(
        () => mockTransactionListBloc.state,
      ).thenReturn(const TransactionListState());

      // ACT
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(transaction: mockTransaction),
      );
      await tester.tap(
        find.byKey(const ValueKey('button_transactionDetail_delete')),
      );
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Confirm Deletion'), findsOneWidget);

      // ACT
      await tester.tap(find.text('Delete'));
      await tester.pump();

      // ASSERT
      verify(
        () => mockTransactionListBloc.add(DeleteTransaction(mockTransaction)),
      ).called(1);
    });
  });
}
