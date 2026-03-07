import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart' as di;
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/router.dart'; // Direct import

import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';

class MockSettingsBloc extends Mock implements SettingsBloc {}

class MockSessionCubit extends Mock implements SessionCubit {}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSettingsBloc settingsBloc;

  setUp(() async {
    settingsBloc = MockSettingsBloc();
    final sessionCubit = MockSessionCubit();

    di.sl.registerSingleton<SettingsBloc>(settingsBloc);
    di.sl.registerSingleton<SessionCubit>(sessionCubit);

    when(() => settingsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => settingsBloc.state).thenReturn(
      const SettingsState(status: SettingsStatus.loaded, setupSkipped: true),
    );
    when(() => sessionCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => sessionCubit.state).thenReturn(SessionUnauthenticated());
  });

  tearDown(() {
    di.sl.reset();
  });

  test('redirects skipped setup to dashboard', () {
    final config = AppRouter.router.configuration;
    final redirect = config.topRedirect;
    final routeState = GoRouterState(
      config,
      uri: Uri.parse(RouteNames.initialSetup),
      matchedLocation: RouteNames.initialSetup,
      fullPath: RouteNames.initialSetup,
      pathParameters: const {},
      pageKey: const ValueKey('page'),
    );
    final result = redirect(FakeBuildContext(), routeState);
    expect(result, RouteNames.dashboard);
  });

  group('login-callback redirect', () {
    test('allows /login-callback when unauthenticated', () {
      final sessionCubit = di.sl<SessionCubit>();
      when(() => sessionCubit.state).thenReturn(SessionUnauthenticated());

      final config = AppRouter.router.configuration;
      final redirect = config.topRedirect;
      final routeState = GoRouterState(
        config,
        uri: Uri.parse('/login-callback'),
        matchedLocation: '/login-callback',
        fullPath: '/login-callback',
        pathParameters: const {},
        pageKey: const ValueKey('page'),
      );

      final result = redirect(FakeBuildContext(), routeState);
      expect(result, null);
    });

    test('allows /login-callback with query params when unauthenticated', () {
      final sessionCubit = di.sl<SessionCubit>();
      when(() => sessionCubit.state).thenReturn(SessionUnauthenticated());

      final config = AppRouter.router.configuration;
      final redirect = config.topRedirect;
      final routeState = GoRouterState(
        config,
        uri: Uri.parse('/login-callback?code=abc#state=xyz'),
        matchedLocation: '/login-callback',
        fullPath: '/login-callback',
        pathParameters: const {},
        pageKey: const ValueKey('page'),
      );

      final result = redirect(FakeBuildContext(), routeState);
      expect(result, null);
    });

    test('redirects /login-callback to dashboard when authenticated', () {
      final sessionCubit = di.sl<SessionCubit>();
      const mockProfile = UserProfile(
        id: '123',
        currency: 'USD',
        timezone: 'UTC',
      );
      when(
        () => sessionCubit.state,
      ).thenReturn(const SessionAuthenticated(mockProfile));

      final config = AppRouter.router.configuration;
      final redirect = config.topRedirect;
      final routeState = GoRouterState(
        config,
        uri: Uri.parse('/login-callback'),
        matchedLocation: '/login-callback',
        fullPath: '/login-callback',
        pathParameters: const {},
        pageKey: const ValueKey('page'),
      );

      final result = redirect(FakeBuildContext(), routeState);
      expect(result, RouteNames.dashboard);
    });

    test('redirects to /lock when SessionLocked even from /login-callback', () {
      final sessionCubit = di.sl<SessionCubit>();
      when(() => sessionCubit.state).thenReturn(SessionLocked());

      final config = AppRouter.router.configuration;
      final redirect = config.topRedirect;
      final routeState = GoRouterState(
        config,
        uri: Uri.parse('/login-callback'),
        matchedLocation: '/login-callback',
        fullPath: '/login-callback',
        pathParameters: const {},
        pageKey: const ValueKey('page'),
      );

      final result = redirect(FakeBuildContext(), routeState);
      expect(result, '/lock');
    });

    test(
      'redirects to /profile-setup when SessionNeedsProfileSetup from /login-callback',
      () {
        final sessionCubit = di.sl<SessionCubit>();
        final mockUser = MockUser();
        when(
          () => sessionCubit.state,
        ).thenReturn(SessionNeedsProfileSetup(mockUser));

        final config = AppRouter.router.configuration;
        final redirect = config.topRedirect;
        final routeState = GoRouterState(
          config,
          uri: Uri.parse('/login-callback'),
          matchedLocation: '/login-callback',
          fullPath: '/login-callback',
          pathParameters: const {},
          pageKey: const ValueKey('page'),
        );

        final result = redirect(FakeBuildContext(), routeState);
        expect(result, '/profile-setup');
      },
    );
  });
}

class MockUser extends Mock implements User {}
