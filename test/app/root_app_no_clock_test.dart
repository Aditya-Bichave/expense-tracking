import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/app/root_app.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionCubit extends Mock implements SessionCubit {}

class MockSettingsBloc extends Mock implements SettingsBloc {}

class MockDeepLinkBloc extends Mock implements DeepLinkBloc {}

void main() {
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
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockDeepLinkBloc.state).thenReturn(DeepLinkInitial());
    when(() => mockDeepLinkBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockSessionCubit.state).thenReturn(SessionUnauthenticated());
    when(() => mockSessionCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('RootApp uses fallback clock when widget.clock is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          BlocProvider<DeepLinkBloc>.value(value: mockDeepLinkBloc),
          BlocProvider<SessionCubit>.value(value: mockSessionCubit),
        ],
        child: const RootApp(),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
