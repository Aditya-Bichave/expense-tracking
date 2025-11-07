import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/account_list_page.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

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

  setUpAll(() {
    registerFallbackValue(const LoadAccounts());
  });

  setUp(() {
    mockBloc = MockAccountListBloc();
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/add',
          name: RouteNames.addAccount,
          builder: (_, __) => const SizedBox(),
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
        accountListBloc: mockBloc,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([const AccountListLoaded(accounts: [], liabilities: [])]),
        initialState: const AccountListLoaded(accounts: [], liabilities: []),
      );
      await pumpWidgetWithProviders(
        tester: tester,
        router: router,
        widget: const AccountListPage(),
        accountListBloc: mockBloc,
      );

      expect(find.text('No accounts yet'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('button_accountList_addFirst')),
      );
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/add',
      );
    });

    testWidgets('shows error state and retries', (tester) async {
      whenListen(
          mockBloc, Stream.fromIterable([const AccountListError('Failed')]),
          initialState: const AccountListError('Failed'));
      await pumpWidgetWithProviders(
          tester: tester,
          widget: const AccountListPage(),
          accountListBloc: mockBloc);

      expect(find.text('Error loading accounts'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('button_accountList_retry')));
      verify(() => mockBloc.add(const LoadAccounts(forceReload: true)))
          .called(1);
    });

    testWidgets('renders a list of AccountCards', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([AccountListLoaded(accounts: mockAccounts, liabilities: [])]),
        initialState: AccountListLoaded(accounts: mockAccounts, liabilities: []),
      );
      await pumpWidgetWithProviders(
          tester: tester,
          widget: const AccountListPage(),
          accountListBloc: mockBloc);
      expect(find.byType(AccountCard), findsNWidgets(2));
    });

    testWidgets('tapping FAB navigates to add page', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([const AccountListLoaded(accounts: [], liabilities: [])]),
        initialState: const AccountListLoaded(accounts: [], liabilities: []),
      );
      await pumpWidgetWithProviders(
        tester: tester,
        router: router,
        widget: const AccountListPage(),
        accountListBloc: mockBloc,
      );

      await tester.tap(find.byKey(const ValueKey('fab_accountList_add')));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/add',
      );
    });
  });
}
