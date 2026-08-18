import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/account_list_page.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_alert_dialog.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late MockAccountListBloc mockBloc;
  late GoRouter router;

  const mockAccounts = [
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

  setUp(() async {
    await sl.reset();
    mockBloc = MockAccountListBloc();
    // The page builds its own BlocProvider from the service locator, so the
    // mock has to be registered there rather than passed into the harness.
    sl.registerFactory<AccountListBloc>(() => mockBloc);

    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const AccountListPage()),
        GoRoute(
          path: '/add',
          name: RouteNames.addAccount,
          builder: (_, __) => const Scaffold(body: Text('Add Account Page')),
        ),
        GoRoute(
          path: '/edit/:accountId',
          name: RouteNames.editAccount,
          builder: (_, __) => const Scaffold(body: Text('Edit Account Page')),
        ),
      ],
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  void stub(AccountListState state) {
    whenListen(
      mockBloc,
      Stream<AccountListState>.fromIterable([state]),
      initialState: state,
    );
  }

  Future<void> pumpPage(WidgetTester tester, {bool settle = true}) async {
    await pumpWidgetWithProviders(
      tester: tester,
      widget: const AccountListPage(),
      router: router,
      accountListBloc: mockBloc,
      settle: settle,
    );
  }

  group('AccountListPage states', () {
    testWidgets('shows a spinner on a first load', (tester) async {
      stub(const AccountListLoading());
      await pumpPage(tester, settle: false);
      await tester.pump();

      expect(find.byType(BridgeCircularProgressIndicator), findsOneWidget);
      expect(find.byType(AccountCard), findsNothing);
    });

    testWidgets('requests accounts as soon as it is built', (tester) async {
      stub(const AccountListLoaded(accounts: mockAccounts));
      await pumpPage(tester);

      verify(() => mockBloc.add(const LoadAccounts())).called(1);
    });

    testWidgets('shows the empty state when there are no accounts', (
      tester,
    ) async {
      stub(const AccountListLoaded(accounts: []));
      await pumpPage(tester);

      expect(find.text('No accounts yet!'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('button_accountList_addFirst')),
        findsOneWidget,
      );
    });

    testWidgets('renders one card per account', (tester) async {
      stub(const AccountListLoaded(accounts: mockAccounts));
      await pumpPage(tester);

      expect(find.byType(AccountCard), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(AccountCard).first,
          matching: find.text('Bank'),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: find.byType(AccountCard).last,
          matching: find.text('Cash'),
        ),
        findsWidgets,
      );
    });

    testWidgets('shows the error state with the failure message', (
      tester,
    ) async {
      stub(const AccountListError('Disk unavailable'));
      await pumpPage(tester);

      expect(find.text('Error loading accounts'), findsOneWidget);
      // The message appears both in the body and in the error snackbar.
      expect(find.text('Disk unavailable'), findsWidgets);
    });

    testWidgets('retry from the error state forces a reload', (tester) async {
      stub(const AccountListError('Disk unavailable'));
      await pumpPage(tester);

      await tester.tap(find.byKey(const ValueKey('button_accountList_retry')));
      await tester.pump();

      verify(
        () => mockBloc.add(const LoadAccounts(forceReload: true)),
      ).called(1);
    });

    testWidgets('a reload keeps the previously loaded cards on screen', (
      tester,
    ) async {
      whenListen(
        mockBloc,
        Stream<AccountListState>.fromIterable([
          const AccountListLoaded(accounts: mockAccounts),
          const AccountListLoading(isReloading: true),
        ]),
        initialState: const AccountListLoaded(accounts: mockAccounts),
      );
      await pumpPage(tester);

      // Reloading must not collapse into the spinner or the empty state.
      expect(find.text('No accounts yet!'), findsNothing);
    });
  });

  group('AccountListPage navigation', () {
    testWidgets('the FAB routes to the add-account page', (tester) async {
      stub(const AccountListLoaded(accounts: mockAccounts));
      await pumpPage(tester);

      await tester.tap(find.byKey(const ValueKey('fab_accountList_add')));
      await tester.pumpAndSettle();

      expect(find.text('Add Account Page'), findsOneWidget);
    });

    testWidgets('the empty-state button routes to the add-account page', (
      tester,
    ) async {
      stub(const AccountListLoaded(accounts: []));
      await pumpPage(tester);

      await tester.tap(
        find.byKey(const ValueKey('button_accountList_addFirst')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Account Page'), findsOneWidget);
    });

    testWidgets('tapping a card routes to the edit page', (tester) async {
      stub(const AccountListLoaded(accounts: mockAccounts));
      await pumpPage(tester);

      await tester.tap(find.byType(AccountCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Account Page'), findsOneWidget);
    });
  });

  group('AccountListPage delete', () {
    testWidgets('swiping a card asks for confirmation before deleting', (
      tester,
    ) async {
      stub(const AccountListLoaded(accounts: mockAccounts));
      await pumpPage(tester);

      await tester.drag(find.byType(AccountCard).first, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Deletion'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(BridgeAlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => mockBloc.add(const DeleteAccountRequested('1'))).called(1);
    });

    testWidgets('cancelling the confirmation leaves the account in place', (
      tester,
    ) async {
      stub(const AccountListLoaded(accounts: mockAccounts));
      await pumpPage(tester);

      await tester.drag(find.byType(AccountCard).first, const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BridgeAlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => mockBloc.add(const DeleteAccountRequested('1')));
      expect(find.byType(AccountCard), findsNWidgets(2));
    });
  });
}
