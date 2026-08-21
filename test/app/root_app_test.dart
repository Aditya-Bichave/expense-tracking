import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/app/root_app.dart';
import 'package:expense_tracker/core/services/clock.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

class MockClock extends Mock implements Clock {}

class MockSessionCubit extends Mock implements SessionCubit {}

class MockSettingsBloc extends Mock implements SettingsBloc {}

class MockDeepLinkBloc extends Mock implements DeepLinkBloc {}

void main() {
  late MockClock mockClock;
  late MockSessionCubit mockSessionCubit;
  late MockSettingsBloc mockSettingsBloc;
  late MockDeepLinkBloc mockDeepLinkBloc;

  setUpAll(() {
    mockSessionCubit = MockSessionCubit();
    mockSettingsBloc = MockSettingsBloc();
    mockDeepLinkBloc = MockDeepLinkBloc();

    if (!sl.isRegistered<SessionCubit>()) {
      sl.registerLazySingleton<SessionCubit>(() => mockSessionCubit);
    }
    if (!sl.isRegistered<SettingsBloc>()) {
      sl.registerLazySingleton<SettingsBloc>(() => mockSettingsBloc);
    }
    if (!sl.isRegistered<DeepLinkBloc>()) {
      sl.registerLazySingleton<DeepLinkBloc>(() => mockDeepLinkBloc);
    }
  });

  setUp(() {
    mockClock = MockClock();

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockDeepLinkBloc.state).thenReturn(DeepLinkInitial());
    when(() => mockDeepLinkBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockSessionCubit.state).thenReturn(SessionUnauthenticated());
    when(() => mockSessionCubit.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockSessionCubit.checkSession(background: any(named: 'background')),
    ).thenAnswer((_) async {});
  });

  testWidgets('RootApp revalidates session when backgrounded >= 60s', (
    tester,
  ) async {
    final now = DateTime(2026, 1, 1, 12, 0, 0);
    when(() => mockClock.now()).thenReturn(now);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          BlocProvider<DeepLinkBloc>.value(value: mockDeepLinkBloc),
          BlocProvider<SessionCubit>.value(value: mockSessionCubit),
        ],
        child: RootApp(clock: mockClock),
      ),
    );

    // Pause app at 12:00:00
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    // Resume app at 12:01:05 (65 seconds later)
    when(
      () => mockClock.now(),
    ).thenReturn(now.add(const Duration(seconds: 65)));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    verify(() => mockSessionCubit.checkSession()).called(1);
  });

  testWidgets('RootApp does NOT revalidate session when backgrounded < 60s', (
    tester,
  ) async {
    final now = DateTime(2026, 1, 1, 12, 0, 0);
    when(() => mockClock.now()).thenReturn(now);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          BlocProvider<DeepLinkBloc>.value(value: mockDeepLinkBloc),
          BlocProvider<SessionCubit>.value(value: mockSessionCubit),
        ],
        child: RootApp(clock: mockClock),
      ),
    );

    // Pause app at 12:00:00
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    // Clear calls recorded during setup/build before resume
    clearInteractions(mockSessionCubit);

    // Resume app at 12:00:30 (30 seconds later)
    when(
      () => mockClock.now(),
    ).thenReturn(now.add(const Duration(seconds: 30)));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    verifyNever(() => mockSessionCubit.checkSession());
  });
}
