import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/accounts_tab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late AccountListBloc mockAccountListBloc;

  setUp(() {
    mockAccountListBloc = MockAccountListBloc();
  });

  testWidgets(
    'AccountsTabPage pull to refresh triggers stream firstWhere and completes',
    (tester) async {
      when(
        () => mockAccountListBloc.state,
      ).thenReturn(const AccountListLoaded(accounts: []));
      when(() => mockAccountListBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AccountListLoading(isReloading: true, previousItems: []),
          const AccountListLoaded(accounts: []),
        ]),
      );

      await pumpWidgetWithProviders(
        tester: tester,
        accountListBloc: mockAccountListBloc,
        widget: const AccountsTabPage(),
      );

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      verify(
        () => mockAccountListBloc.add(const LoadAccounts(forceReload: true)),
      ).called(1);
    },
  );

  testWidgets(
    'AccountsTabPage pull to refresh handles TimeoutException gracefully',
    (tester) async {
      when(
        () => mockAccountListBloc.state,
      ).thenReturn(const AccountListLoaded(accounts: []));
      when(
        () => mockAccountListBloc.stream,
      ).thenAnswer((_) => const Stream.empty());

      await pumpWidgetWithProviders(
        tester: tester,
        accountListBloc: mockAccountListBloc,
        widget: const AccountsTabPage(),
      );

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      verify(
        () => mockAccountListBloc.add(const LoadAccounts(forceReload: true)),
      ).called(1);
    },
  );
}
