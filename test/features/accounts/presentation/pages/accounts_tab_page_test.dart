import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/accounts_tab_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Import the widget itself to find it
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';

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

    // Default initial state for generic tests
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
    await tester.pump(); // Use pump instead of pumpAndSettle due to infinite loading animation in initial state

    expect(find.byType(AccountsTabPage), findsOneWidget);
  });

  testWidgets('renders loading state correctly', (tester) async {
    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListLoading());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Start animation

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders loaded accounts list correctly', (tester) async {
    final accounts = [
      const AssetAccount(
        id: '1',
        name: 'Bank Account',
        type: AssetType.bank,
        currentBalance: 1000.0,
      ),
      const AssetAccount(
        id: '2',
        name: 'Savings',
        type: AssetType.cash,
        currentBalance: 5000.0,
      ),
    ];

    when(
      () => mockAccountListBloc.state,
    ).thenReturn(AccountListLoaded(accounts: accounts));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify headers and total assets are shown
    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Total Assets:'), findsOneWidget);

    // Verify account cards are rendered
    expect(find.byType(AccountCard), findsNWidgets(2));
    expect(find.text('Bank Account'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);

    // Verify CustomScrollView is used (by checking for Slivers indirectly via scrolling behavior or structure if needed,
    // but verifying content renders implies the sliver list is working)
    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('renders empty state correctly', (tester) async {
    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListLoaded(accounts: []));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('No asset accounts added yet'), findsOneWidget);
    expect(find.byType(AccountCard), findsNothing);
  });
}
