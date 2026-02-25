import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/pages/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import '../../../../helpers/pump_app.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSessionCubit extends Mock implements SessionCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockSecureStorageService mockStorage;
  late MockSessionCubit mockSessionCubit;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockStorage = MockSecureStorageService();
    mockSessionCubit = MockSessionCubit();
    mockAuthBloc = MockAuthBloc();

    // Register the mock storage in GetIt (sl)
    if (sl.isRegistered<SecureStorageService>()) {
      sl.unregister<SecureStorageService>();
    }
    sl.registerSingleton<SecureStorageService>(mockStorage);
  });

  tearDown(() {
    sl.reset();
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: mockSessionCubit),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: const MaterialApp(home: LockScreen()),
    );
  }

  testWidgets(
    'shows reset dialog when PIN is missing and user enters 4 digits',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // ARRANGE
      when(
        () => mockStorage.getPin(),
      ).thenAnswer((_) async => null); // Missing PIN

      // ACT
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle(); // Allow init to run

      // Enter 4 digits
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump(); // This triggers _verifyPin

      await tester.pumpAndSettle(); // Wait for dialog

      // ASSERT
      expect(find.text('Security Configuration Error'), findsOneWidget);
      expect(find.text('Logout & Reset'), findsOneWidget);

      // Verify tapping Logout triggers event
      await tester.tap(find.text('Logout & Reset'));
      verify(() => mockAuthBloc.add(AuthLogoutRequested())).called(1);
    },
  );
}
