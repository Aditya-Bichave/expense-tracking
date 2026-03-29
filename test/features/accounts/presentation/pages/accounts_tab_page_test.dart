import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/accounts_tab_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockAccountListBloc mockAccountListBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockAccountListBloc = MockAccountListBloc();
    mockSettingsBloc = MockSettingsBloc();

    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListInitial());
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccountsTabPage(),
      ),
    );
  }

  testWidgets('renders AccountsTabPage', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(AccountsTabPage), findsOneWidget);
    // Might have "Accounts" header
    // expect(find.text('Accounts'), findsOneWidget);
  });

  testWidgets('pull to refresh triggers timeout handling correctly', (tester) async {
    // Return a stream that never emits to trigger the timeout
    when(() => mockAccountListBloc.stream).thenAnswer((_) => const Stream.empty());
    // Simulate loading state so ListView is rendered instead of a loading spinner
    when(() => mockAccountListBloc.state).thenReturn(const AccountListLoaded(accounts: []));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Find the RefreshIndicator (by finding a ListView which is a child of RefreshIndicator)
    final listView = find.byType(ListView);
    expect(listView, findsWidgets);

    // Perform the pull-down gesture to trigger onRefresh
    await tester.fling(listView.first, const Offset(0, 300), 1000);
    await tester.pump();

    // Fast-forward past the 3-second timeout duration
    await tester.pump(const Duration(seconds: 4));

    // Verify LoadAccounts was triggered
    verify(() => mockAccountListBloc.add(const LoadAccounts(forceReload: true))).called(1);
  });
}
