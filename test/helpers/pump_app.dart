import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// Helper class for mocking GoRouter
class MockGoRouter extends Mock implements GoRouter {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

// The Test Harness Function
Future<void> pumpWidgetWithProviders({
  required WidgetTester tester,
  required Widget widget,
  // --- Mocks & Stubs ---
  SettingsState? settingsState, // Easily provide a specific settings state
  List<BlocProvider> blocProviders =
      const [], // For other feature-specific Blocs
  GetIt? getIt, // Pass a pre-configured service locator if needed
  GoRouter? router, // Optional router configuration
}) async {
  // 1. Determine router configuration
  final routerConfig = router ??
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
      settingsState ?? const SettingsState()
    ]), // Use provided state or default
    initialState: settingsState ?? const SettingsState(),
  );

  // 3. Wrap the widget in all necessary providers
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        // Provide the essential SettingsBloc
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        // Add any other feature-specific mock Blocs passed to the function
        ...blocProviders,
      ],
      child: MaterialApp.router(
        // Use MaterialApp.router to satisfy GoRouter context
        localizationsDelegates: const [],
        supportedLocales: const [Locale('en')],
        // Build the theme dynamically based on the provided settingsState
        theme: AppTheme.buildTheme(
          settingsState?.uiMode ?? UIMode.elemental,
          settingsState?.paletteIdentifier ?? AppTheme.elementalPalette1,
        ).light,
        darkTheme: AppTheme.buildTheme(
          settingsState?.uiMode ?? UIMode.elemental,
          settingsState?.paletteIdentifier ?? AppTheme.elementalPalette1,
        ).dark,
        themeMode: settingsState?.themeMode ?? ThemeMode.system,

        // Provide the router configuration
        routerConfig: routerConfig,
      ),
    ),
  );
}
