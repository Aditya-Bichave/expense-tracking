import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/features/auth/presentation/pages/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSessionCubit mockSessionCubit;
  late MockSecureStorageService mockSecureStorageService;
  final getIt = GetIt.instance;

  setUp(() {
    mockSessionCubit = MockSessionCubit();
    mockSecureStorageService = MockSecureStorageService();

    if (getIt.isRegistered<SecureStorageService>()) {
      getIt.unregister<SecureStorageService>();
    }
    getIt.registerSingleton<SecureStorageService>(mockSecureStorageService);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/local_auth'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isDeviceSupported') {
              return false;
            }
            if (methodCall.method == 'getAvailableBiometrics') {
              return <String>[];
            }
            if (methodCall.method == 'authenticate') {
              return false;
            }
            return null;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/local_auth'),
          null,
        );
    getIt.reset();
  });

  Widget createWidget() {
    return BlocProvider<SessionCubit>.value(
      value: mockSessionCubit,
      child: const MaterialApp(home: LockScreen()),
    );
  }

  testWidgets('LockScreen renders keypad', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockSecureStorageService.getPin(),
    ).thenAnswer((_) async => '1234');

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('App Locked'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
  });

  testWidgets('Entering correct PIN unlocks session', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockSecureStorageService.getPin(),
    ).thenAnswer((_) async => '1234');
    when(() => mockSessionCubit.unlock()).thenAnswer((_) async {});

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();

    verify(() => mockSessionCubit.unlock()).called(1);
  });

  testWidgets('Entering incorrect PIN shows error', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockSecureStorageService.getPin(),
    ).thenAnswer((_) async => '1234');

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();

    verifyNever(() => mockSessionCubit.unlock());
    expect(find.text('Incorrect PIN'), findsOneWidget);
  });

  testWidgets('Backspace removes digit', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockSecureStorageService.getPin(),
    ).thenAnswer((_) async => '1234');

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();

    verifyNever(() => mockSessionCubit.unlock());
    expect(find.text('Incorrect PIN'), findsNothing);
  });
}
