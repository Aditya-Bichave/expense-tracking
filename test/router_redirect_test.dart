import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart' as di;
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/router.dart' deferred as app_router;

class MockSettingsBloc extends Mock implements SettingsBloc {}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSettingsBloc settingsBloc;

  setUp(() async {
    settingsBloc = MockSettingsBloc();
    di.sl.registerSingleton<SettingsBloc>(settingsBloc);
    when(() => settingsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => settingsBloc.state).thenReturn(
      const SettingsState(status: SettingsStatus.loaded, setupSkipped: true),
    );
    await app_router.loadLibrary();
  });

  tearDown(() {
    di.sl.reset();
  });

  test('redirects skipped setup to dashboard', () {
    final redirect = app_router.AppRouter.router.configuration.topRedirect;
    final routeState = GoRouterState(
      RouteConfiguration(
        routes: const [],
        redirectLimit: 20,
        topRedirect: (_, __) => null,
        navigatorKey: GlobalKey<NavigatorState>(),
      ),
      uri: Uri.parse(RouteNames.initialSetup),
      matchedLocation: RouteNames.initialSetup,
      fullPath: RouteNames.initialSetup,
      pathParameters: const {},
      pageKey: const ValueKey('page'),
    );
    final result = redirect(FakeBuildContext(), routeState);
    expect(result, RouteNames.dashboard);
  });
}
