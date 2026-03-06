import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart' as di;
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/router.dart' deferred as app_router;

class MockSettingsBloc extends Mock implements SettingsBloc {}

class MockSessionCubit extends Mock implements SessionCubit {}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSettingsBloc settingsBloc;
  late MockSessionCubit sessionCubit;

  setUp(() async {
    settingsBloc = MockSettingsBloc();
    sessionCubit = MockSessionCubit();

    di.sl.registerSingleton<SettingsBloc>(settingsBloc);
    di.sl.registerSingleton<SessionCubit>(sessionCubit);

    when(() => settingsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => sessionCubit.stream).thenAnswer((_) => const Stream.empty());

    await app_router.loadLibrary();
  });

  tearDown(() {
    di.sl.reset();
  });

  GoRouterState createRouteState(String location) {
    return GoRouterState(
      app_router.AppRouter.router.configuration,
      uri: Uri.parse(location),
      matchedLocation: location,
      fullPath: location,
      pathParameters: const {},
      pageKey: const ValueKey('page'),
    );
  }

  group('Router Redirects', () {
    test('redirects to lock screen when session is locked', () {
      when(() => sessionCubit.state).thenReturn(SessionLocked());
      when(() => settingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.loaded, setupSkipped: true),
      );

      final redirect = app_router.AppRouter.router.configuration.topRedirect;
      final result = redirect(
        FakeBuildContext(),
        createRouteState(RouteNames.dashboard),
      );

      expect(result, '/lock');
    });

    test('stays on lock screen when session is locked', () {
      when(() => sessionCubit.state).thenReturn(SessionLocked());
      when(() => settingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.loaded, setupSkipped: true),
      );

      final redirect = app_router.AppRouter.router.configuration.topRedirect;
      final result = redirect(FakeBuildContext(), createRouteState('/lock'));

      expect(result, null);
    });

    test('redirects skipped setup to dashboard', () {
      when(() => sessionCubit.state).thenReturn(SessionUnauthenticated());
      when(() => settingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.loaded, setupSkipped: true),
      );

      final redirect = app_router.AppRouter.router.configuration.topRedirect;
      final result = redirect(
        FakeBuildContext(),
        createRouteState(RouteNames.initialSetup),
      );

      expect(result, RouteNames.dashboard);
    });

    test(
      'redirects unauthenticated without guest mode to initial setup if not logging in',
      () {
        when(() => sessionCubit.state).thenReturn(SessionUnauthenticated());
        when(() => settingsBloc.state).thenReturn(
          const SettingsState(
            status: SettingsStatus.loaded,
            setupSkipped: false,
          ),
        );

        final redirect = app_router.AppRouter.router.configuration.topRedirect;
        final result = redirect(
          FakeBuildContext(),
          createRouteState(RouteNames.dashboard),
        );

        expect(result, RouteNames.initialSetup);
      },
    );

    test('allows unauthenticated users to access login route', () {
      when(() => sessionCubit.state).thenReturn(SessionUnauthenticated());
      when(() => settingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.loaded, setupSkipped: false),
      );

      final redirect = app_router.AppRouter.router.configuration.topRedirect;
      final result = redirect(
        FakeBuildContext(),
        createRouteState(RouteNames.login),
      );

      expect(result, null);
    });

    test('redirects authenticated users away from login to dashboard', () {
      when(() => sessionCubit.state).thenReturn(
        const SessionAuthenticated(
          UserProfile(
            id: '1',
            email: 'test@test.com',
            currency: 'USD',
            timezone: 'UTC',
          ),
        ),
      );
      when(() => settingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.loaded, setupSkipped: false),
      );

      final redirect = app_router.AppRouter.router.configuration.topRedirect;
      final result = redirect(
        FakeBuildContext(),
        createRouteState(RouteNames.login),
      );

      expect(result, RouteNames.dashboard);
    });

    test('allows authenticated users to access dashboard', () {
      when(() => sessionCubit.state).thenReturn(
        const SessionAuthenticated(
          UserProfile(
            id: '1',
            email: 'test@test.com',
            currency: 'USD',
            timezone: 'UTC',
          ),
        ),
      );
      when(() => settingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.loaded, setupSkipped: false),
      );

      final redirect = app_router.AppRouter.router.configuration.topRedirect;
      final result = redirect(
        FakeBuildContext(),
        createRouteState(RouteNames.dashboard),
      );

      expect(result, null);
    });
  });
}
