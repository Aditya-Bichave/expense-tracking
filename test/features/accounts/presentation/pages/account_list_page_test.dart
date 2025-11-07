import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability_enums.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/account_list_page.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/liability_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late AccountListBloc mockBloc;
  late GoRouter router;

  final mockAccounts = const [
    AssetAccount(
      id: '1',
      name: 'Bank',
      type: AssetType.bank,
      initialBalance: 1000,
      currentBalance: 1000,
    ),
    AssetAccount(
      id: '2',
      name: 'Cash',
      type: AssetType.cash,
      initialBalance: 200,
      currentBalance: 200,
    ),
  ];
  final List<Liability> mockLiabilities = [
    Liability(
      id: 'l1',
      name: 'Credit Card',
      type: LiabilityType.creditCard,
      initialBalance: 500,
      currentBalance: 250,
      creditLimit: 1000,
    )
  ];

  setUpAll(() {
    registerFallbackValue(const LoadAccounts());
  });

  setUp(() {
    mockBloc = MockAccountListBloc();
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
            path: '/',
            builder: (_, __) => BlocProvider.value(
                  value: mockBloc,
                  child: const AccountListPage(),
                )),
        GoRoute(
          path: '/${RouteNames.addAccount}',
          name: RouteNames.addAccount,
          builder: (_, __) => const SizedBox(key: Key('addAccountPage')),
        ),
        GoRoute(
          path: '/${RouteNames.addLiability}',
          name: RouteNames.addLiability,
          builder: (_, __) => const SizedBox(key: Key('addLiabilityPage')),
        ),
      ],
    );
    sl.registerFactory<AccountListBloc>(() => mockBloc);
  });

  tearDown(() {
    sl.reset();
  });

  group('AccountListPage', () {
    testWidgets('shows loading indicator', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([const AccountListLoading()]),
        initialState: const AccountListLoading(),
      );
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AccountListPage(),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable(
            [const AccountListLoaded(accounts: [], liabilities: [])]),
        initialState: const AccountListLoaded(accounts: [], liabilities: []),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assets'), findsOneWidget);
      expect(find.text('Credit & Loans'), findsOneWidget);
      expect(find.byType(AccountCard), findsNothing);
      expect(find.byType(LiabilityCard), findsNothing);
    });

    testWidgets('shows error state and retries', (tester) async {
      whenListen(
          mockBloc, Stream.fromIterable([const AccountListError('Failed')]),
          initialState: const AccountListError('Failed'));
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error loading accounts'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('button_accountList_retry')));
      verify(() => mockBloc.add(const LoadAccounts(forceReload: true)))
          .called(1);
    });

    testWidgets('renders a list of AccountCards and LiabilityCards',
        (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([
          AccountListLoaded(
              accounts: mockAccounts, liabilities: mockLiabilities)
        ]),
        initialState: AccountListLoaded(
            accounts: mockAccounts, liabilities: mockLiabilities),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AccountCard), findsNWidgets(2));
      expect(find.byType(LiabilityCard), findsNWidgets(1));
    });

    testWidgets('tapping FAB shows add account modal', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable(
            [const AccountListLoaded(accounts: [], liabilities: [])]),
        initialState: const AccountListLoaded(accounts: [], liabilities: []),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('fab_accountList_add')));
      await tester.pumpAndSettle();

      expect(find.text('Add Asset'), findsOneWidget);
      expect(find.text('Add Credit/Loan'), findsOneWidget);
    });

    testWidgets('tapping "Add Asset" navigates to add account page',
        (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable(
            [const AccountListLoaded(accounts: [], liabilities: [])]),
        initialState: const AccountListLoaded(accounts: [], liabilities: []),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('fab_accountList_add')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Asset'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addAccountPage')), findsOneWidget);
    });

    testWidgets('tapping "Add Credit/Loan" navigates to add liability page',
        (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable(
            [const AccountListLoaded(accounts: [], liabilities: [])]),
        initialState: const AccountListLoaded(accounts: [], liabilities: []),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('fab_accountList_add')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Credit/Loan'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addLiabilityPage')), findsOneWidget);
    });
  });
}
