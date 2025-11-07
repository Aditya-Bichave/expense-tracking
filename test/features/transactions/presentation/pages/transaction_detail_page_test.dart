import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
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

  final mockTransaction = Transaction(
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
    fromAccountId: 'acc1',
    type: TransactionType.expense,
  );

  final mockAccount = AssetAccount(
    id: 'acc1',
    name: 'Main Bank',
    type: AssetType.bank,
    initialBalance: 1000,
    currentBalance: 1000,
  );

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionListBloc>.value(value: mockTransactionListBloc),
        BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
      ],
      child: TransactionDetailPage(transaction: mockTransaction),
    );
  }

  group('TransactionDetailPage', () {
    testWidgets('renders all transaction details correctly', (tester) async {
      // ARRANGE
      when(() => mockAccountListBloc.state)
          .thenReturn(AccountListLoaded(accounts: [mockAccount], liabilities: []));

      // ACT
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      // ASSERT
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('- \$4.50'), findsOneWidget);
      expect(find.text('Jan 1, 2023 12:00 AM'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Main Bank'), findsOneWidget);
    });

    testWidgets('tapping Edit button does not throw', (tester) async {
      when(() => mockAccountListBloc.state)
          .thenReturn(const AccountListInitial());

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => buildTestWidget()),
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

      final editFinder =
          find.byKey(const ValueKey('button_transactionDetail_edit'));
      expect(editFinder, findsOneWidget);
      await tester.tap(editFinder);
      await tester.pump();
    });

    testWidgets('tapping Delete button shows dialog and dispatches event',
        (tester) async {
      // ARRANGE
      when(() => mockAccountListBloc.state)
          .thenReturn(const AccountListInitial());
      when(() => mockTransactionListBloc.state)
          .thenReturn(const TransactionListState());

      // ACT
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      await tester
          .tap(find.byKey(const ValueKey('button_transactionDetail_delete')));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Confirm Deletion'), findsOneWidget);

      // ACT
      await tester.tap(find.text('Delete'));
      await tester.pump();

      // ASSERT
      verify(() =>
              mockTransactionListBloc.add(DeleteTransaction(mockTransaction)))
          .called(1);
    });
  });
}
