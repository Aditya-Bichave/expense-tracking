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
}
