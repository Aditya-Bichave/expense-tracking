import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/account_list_page.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/add_edit_account_page.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_form.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAddAssetAccountUseCase extends Mock
    implements AddAssetAccountUseCase {}

class MockUpdateAssetAccountUseCase extends Mock
    implements UpdateAssetAccountUseCase {}

class _FakeAddParams extends Fake implements AddAssetAccountParams {}

class _FakeUpdateParams extends Fake implements UpdateAssetAccountParams {}

void main() {
  late MockAccountListBloc accountListBloc;
  late MockSettingsBloc settingsBloc;
  late MockAddAssetAccountUseCase addAccount;
  late MockUpdateAssetAccountUseCase updateAccount;

  const bank = AssetAccount(
    id: 'a1',
    name: 'Bank',
    type: AssetType.bank,
    initialBalance: 1000,
    currentBalance: 1200,
  );

  setUpAll(() {
    registerFallbackValue(_FakeAddParams());
    registerFallbackValue(_FakeUpdateParams());
    registerFallbackValue(const LoadAccounts());
  });

  setUp(() async {
    await sl.reset();
    accountListBloc = MockAccountListBloc();
    settingsBloc = MockSettingsBloc();
    addAccount = MockAddAssetAccountUseCase();
    updateAccount = MockUpdateAssetAccountUseCase();

    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(
      () => accountListBloc.state,
    ).thenReturn(const AccountListLoaded(accounts: []));

    sl.registerFactory<AccountListBloc>(() => accountListBloc);
    // The add/edit page pulls its bloc from the locator with the account to
    // edit passed as param1; the real bloc is under test here.
    sl.registerFactoryParam<AddEditAccountBloc, AssetAccount?, void>(
      (initialAccount, _) => AddEditAccountBloc(
        addAssetAccountUseCase: addAccount,
        updateAssetAccountUseCase: updateAccount,
        initialAccount: initialAccount,
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpFlow(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/accounts',
      routes: [
        GoRoute(
          path: '/accounts',
          name: 'accounts',
          builder: (_, __) => const AccountListPage(),
          routes: [
            GoRoute(
              path: 'add',
              name: RouteNames.addAccount,
              builder: (_, __) => const AddEditAccountPage(),
            ),
            GoRoute(
              path: 'edit/:accountId',
              name: RouteNames.editAccount,
              builder: (_, state) => AddEditAccountPage(
                accountId: state.pathParameters['accountId'],
                account: state.extra as AssetAccount?,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<AccountListBloc>.value(value: accountListBloc),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAccountForm(
    WidgetTester tester, {
    required String name,
    required String balance,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.last, balance);
    await tester.pump();
  }

  Future<void> submitAccountForm(WidgetTester tester) async {
    final submit = find.byKey(const ValueKey('button_accountForm_submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  group('E2E: create an account', () {
    testWidgets('empty list -> FAB -> form -> AddAssetAccountUseCase', (
      tester,
    ) async {
      when(() => addAccount(any())).thenAnswer((_) async => const Right(bank));

      await pumpFlow(tester);
      expect(find.text('No accounts yet!'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('fab_accountList_add')));
      await tester.pumpAndSettle();
      expect(find.text('Add Account'), findsWidgets);
      expect(find.byType(AccountForm), findsOneWidget);

      await fillAccountForm(tester, name: 'Everyday Checking', balance: '250');
      await submitAccountForm(tester);

      final params =
          verify(() => addAccount(captureAny())).captured.single
              as AddAssetAccountParams;
      expect(params.account.name, 'Everyday Checking');
      expect(params.account.initialBalance, 250);
    });

    testWidgets('a successful save returns to the account list', (
      tester,
    ) async {
      when(() => addAccount(any())).thenAnswer((_) async => const Right(bank));

      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('fab_accountList_add')));
      await tester.pumpAndSettle();
      await fillAccountForm(tester, name: 'Savings', balance: '10');
      await submitAccountForm(tester);

      expect(find.byType(AccountForm), findsNothing);
      expect(find.text('Account added successfully!'), findsOneWidget);
    });

    testWidgets('an empty name is rejected before the use case runs', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('fab_accountList_add')));
      await tester.pumpAndSettle();

      await submitAccountForm(tester);

      verifyNever(() => addAccount(any()));
      expect(
        find.text('Please correct the errors in the form.'),
        findsOneWidget,
      );
    });

    testWidgets('a save failure surfaces the error and keeps the form open', (
      tester,
    ) async {
      when(() => addAccount(any())).thenAnswer(
        (_) async => const Left(ValidationFailure('Name already in use')),
      );

      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('fab_accountList_add')));
      await tester.pumpAndSettle();
      await fillAccountForm(tester, name: 'Bank', balance: '0');
      await submitAccountForm(tester);

      expect(find.text('Error: Name already in use'), findsOneWidget);
      expect(find.byType(AccountForm), findsOneWidget);
    });
  });

  group('E2E: edit an account', () {
    testWidgets('tapping a card opens edit and routes to the update use case', (
      tester,
    ) async {
      when(
        () => accountListBloc.state,
      ).thenReturn(const AccountListLoaded(accounts: [bank]));
      when(
        () => updateAccount(any()),
      ).thenAnswer((_) async => const Right(bank));

      await pumpFlow(tester);
      expect(find.byType(AccountCard), findsOneWidget);

      await tester.tap(find.byType(AccountCard));
      await tester.pumpAndSettle();

      expect(find.text('Edit Account'), findsOneWidget);

      await fillAccountForm(tester, name: 'Renamed Bank', balance: '999');
      await submitAccountForm(tester);

      final params =
          verify(() => updateAccount(captureAny())).captured.single
              as UpdateAssetAccountParams;
      expect(params.account.id, 'a1');
      expect(params.account.name, 'Renamed Bank');
      expect(params.account.initialBalance, 999);
      verifyNever(() => addAccount(any()));
    });

    testWidgets('the edit form opens seeded with the existing account', (
      tester,
    ) async {
      when(
        () => accountListBloc.state,
      ).thenReturn(const AccountListLoaded(accounts: [bank]));

      await pumpFlow(tester);
      await tester.tap(find.byType(AccountCard));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Bank'), findsOneWidget);
    });
  });
}
