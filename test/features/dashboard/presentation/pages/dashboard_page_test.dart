import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/l10n/app_localizations.dart'; // Import Localizations

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late MockDashboardBloc mockDashboardBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockAccountListBloc mockAccountListBloc;

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockAccountListBloc = MockAccountListBloc();

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListInitial());
  });

  testWidgets('Refresh indicator triggers LoadDashboard and completes', (
    tester,
  ) async {
    final emptyOverview = const FinancialOverview(
      totalIncome: 0,
      totalExpenses: 0,
      netFlow: 0,
      overallBalance: 0,
      accounts: [],
      accountBalances: {},
      activeBudgetsSummary: [],
      activeGoalsSummary: [],
      recentSpendingSparkline: [],
      recentContributionSparkline: [],
    );

    when(
      () => mockDashboardBloc.state,
    ).thenReturn(DashboardLoaded(emptyOverview));

    whenListen(
      mockDashboardBloc,
      Stream.fromIterable([
        const DashboardLoading(isReloading: true),
        DashboardLoaded(emptyOverview),
      ]),
      initialState: DashboardLoaded(emptyOverview),
    );

    const testAppModeTheme = AppModeTheme(
      modeId: 'test',
      layoutDensity: LayoutDensity.comfortable,
      cardStyle: CardStyle.elevated,
      assets: ThemeAssetPaths(),
      preferDataTableForLists: false,
      primaryAnimationDuration: Duration(milliseconds: 300),
      listEntranceAnimation: ListEntranceAnimation.none,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>(create: (_) => mockDashboardBloc),
          BlocProvider<SettingsBloc>(create: (_) => mockSettingsBloc),
          BlocProvider<AccountListBloc>(create: (_) => mockAccountListBloc),
        ],
        child: MaterialApp(
          localizationsDelegates:
              AppLocalizations.localizationsDelegates, // Add delegates
          supportedLocales: AppLocalizations.supportedLocales, // Add locales
          theme: ThemeData(extensions: const [testAppModeTheme]),
          home: const DashboardPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    verify(
      () => mockDashboardBloc.add(const LoadDashboard(forceReload: true)),
    ).called(1);
  });
}
