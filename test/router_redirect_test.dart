import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart' as di;
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/router.dart'; // Direct import

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
  });

  tearDown(() {
    di.sl.reset();
  });

  test('redirects skipped setup to dashboard', () {
    final config = AppRouter.router.configuration; // Assuming AppRouter is the class name in router.dart
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
}
