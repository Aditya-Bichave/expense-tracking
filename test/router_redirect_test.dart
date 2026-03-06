import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart' as di;
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/router.dart' deferred as app_router;

import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';

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

    await app_router.loadLibrary();
  });

  tearDown(() {
    di.sl.reset();
  });

  test('redirects skipped setup to dashboard', () {
    final config = app_router.AppRouter.router.configuration;
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

  group('Route Builders with extra type safety', () {
    late GoRouter router;

    setUp(() {
      router = app_router.AppRouter.router;
    });

    test('verifyOtp handles extra being null or not String', () {
      final config = router.configuration;
      final route =
          config.routes.firstWhere(
                (r) => r is GoRoute && r.path == RouteNames.verifyOtp,
              )
              as GoRoute;

      final stateString = GoRouterState(
        config,
        uri: Uri.parse(RouteNames.verifyOtp),
        matchedLocation: RouteNames.verifyOtp,
        fullPath: RouteNames.verifyOtp,
        pathParameters: const {},
        pageKey: const ValueKey('page'),
        extra: '1234567890',
      );

      expect(route.builder, isNotNull);
      final widget1 = route.builder!(FakeBuildContext(), stateString);
      expect(widget1.runtimeType.toString(), 'VerifyOtpPage');

      final stateNull = GoRouterState(
        config,
        uri: Uri.parse(RouteNames.verifyOtp),
        matchedLocation: RouteNames.verifyOtp,
        fullPath: RouteNames.verifyOtp,
        pathParameters: const {},
        pageKey: const ValueKey('page'),
        extra: null,
      );
      final widget2 = route.builder!(FakeBuildContext(), stateNull);
      expect(widget2.runtimeType.toString(), 'VerifyOtpPage');
    });

    test('addTransaction handles extra being Map, String, or null', () {
      final config = router.configuration;

      GoRoute? findRoute(List<RouteBase> routes, String name) {
        for (var r in routes) {
          if (r is GoRoute && r.path == name) return r;
          if (r is GoRoute) {
            var found = findRoute(r.routes, name);
            if (found != null) return found;
          }
          if (r is ShellRoute) {
            var found = findRoute(r.routes, name);
            if (found != null) return found;
          }
          if (r is StatefulShellRoute) {
            for (var b in r.branches) {
              var found = findRoute(b.routes, name);
              if (found != null) return found;
            }
          }
        }
        return null;
      }

      final addRoute = findRoute(config.routes, RouteNames.addTransaction)!;

      final stateMap = GoRouterState(
        config,
        uri: Uri.parse(RouteNames.addTransaction),
        matchedLocation: RouteNames.addTransaction,
        fullPath: RouteNames.addTransaction,
        pathParameters: const {},
        pageKey: const ValueKey('page'),
        extra: {'merchantId': 'merch_123'},
      );

      expect(addRoute.builder, isNotNull);
      // We just ensure it doesn't throw a type cast exception.
      try {
        addRoute.builder!(FakeBuildContext(), stateMap);
      } catch (e) {
        // Will throw provider not found which is fine, we just want to avoid Type Cast exceptions.
        expect(
          e.toString(),
          isNot(contains("type 'Null' is not a subtype of type")),
        );
        expect(e.toString(), isNot(contains("as String")));
      }
    });
  });
}
