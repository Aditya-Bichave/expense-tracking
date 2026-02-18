import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'mock_helpers.dart';

// Helper class for mocking GoRouter
class MockGoRouter extends Mock implements GoRouter {
  @override
  GoRouteInformationProvider get routeInformationProvider =>
      GoRouteInformationProvider(initialLocation: '/', initialExtra: null);

  @override
  GoRouteInformationParser get routeInformationParser =>
      GoRouter(routes: []).routeInformationParser;

  @override
  GoRouterDelegate get routerDelegate => GoRouter(routes: []).routerDelegate;

  @override
  BackButtonDispatcher get backButtonDispatcher =>
      GoRouter(routes: []).backButtonDispatcher;
}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

// The Test Harness Function
Future<void> pumpWidgetWithProviders({
  required WidgetTester tester,
  required Widget widget,
  // --- Mocks & Stubs ---
  SettingsState? settingsState, // Easily provide a specific settings state
  AccountListState? accountListState,
  AccountListBloc? accountListBloc,
  List<BlocProvider> blocProviders =
      const [], // For other feature-specific Blocs
  GetIt? getIt, // Pass a pre-configured service locator if needed
  GoRouter? router, // Optional router configuration
  bool settle = true,
  ThemeData? theme,
  ThemeData? darkTheme,
}) async {
  // 1. Determine router configuration
  final routerConfig =
      router ??
      GoRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(body: widget),
          ),
        ],
      );

  // 2. Prepare the settings state and mock SettingsBloc
  final mockSettingsBloc = MockSettingsBloc();
  whenListen(
    mockSettingsBloc,
    Stream.fromIterable([
      settingsState ?? const SettingsState(),
    ]), // Use provided state or default
    initialState: settingsState ?? const SettingsState(),
  );

  final mockAccountListBloc = accountListBloc ?? MockAccountListBloc();
  if (accountListBloc == null) {
    whenListen(
      mockAccountListBloc,
      Stream<AccountListState>.fromIterable([
        accountListState ?? const AccountListInitial(),
      ]),
      initialState: accountListState ?? const AccountListInitial(),
    );
  }

  // 3. Wrap the widget in all necessary providers
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        // Provide the essential SettingsBloc
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
        // Add any other feature-specific mock Blocs passed to the function
        ...blocProviders,
      ],
      child: MaterialApp.router(
        // Use MaterialApp.router to satisfy GoRouter context
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Build the theme dynamically based on the provided settingsState
        theme:
            theme ??
            AppTheme.buildTheme(
              settingsState?.uiMode ?? UIMode.elemental,
              settingsState?.paletteIdentifier ?? AppTheme.elementalPalette1,
            ).light,
        darkTheme:
            darkTheme ??
            AppTheme.buildTheme(
              settingsState?.uiMode ?? UIMode.elemental,
              settingsState?.paletteIdentifier ?? AppTheme.elementalPalette1,
            ).dark,
        themeMode: settingsState?.themeMode ?? ThemeMode.system,

        // Provide the router configuration
        routerConfig: routerConfig,
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  }
}
