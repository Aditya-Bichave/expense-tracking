import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionCubit extends Mock implements SessionCubit {}

class MockSettingsBloc extends Mock implements SettingsBloc {}

void main() {
  setUp(() {
    sl.reset();
    final mockSessionCubit = MockSessionCubit();
    when(() => mockSessionCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockSessionCubit.state).thenReturn(SessionUnauthenticated());

    final mockSettingsBloc = MockSettingsBloc();
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());

    sl.registerLazySingleton<SessionCubit>(() => mockSessionCubit);
    sl.registerLazySingleton<SettingsBloc>(() => mockSettingsBloc);
  });

  test('AppRouter configuration has valid routes', () {
    final router = AppRouter.router;
    expect(router, isNotNull);

    // Check router configuration
    final routeConfig = router.configuration;
    expect(routeConfig.routes.isNotEmpty, isTrue);
  });
}
