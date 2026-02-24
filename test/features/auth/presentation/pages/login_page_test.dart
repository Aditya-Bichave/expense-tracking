import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockGoRouter mockGoRouter;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockGoRouter = MockGoRouter();
    registerFallbackValue(Uri()); // Just in case
    when(
      () => mockGoRouter.push(any(), extra: any(named: 'extra')),
    ).thenAnswer((_) async => null);
  });

  Widget createWidget() {
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: const LoginPage(),
        ),
      ),
    );
  }

  testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());

    await tester.pumpWidget(createWidget());

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget); // Initially on Phone tab?
    // TabController index 0 is Phone.

    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('Switching tabs works', (WidgetTester tester) async {
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());

    await tester.pumpWidget(createWidget());

    // Tap Email tab
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    expect(find.text('Send Magic Link'), findsOneWidget);
  });

  testWidgets('Enter phone and submit sends AuthLoginRequested', (
    WidgetTester tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());

    await tester.pumpWidget(createWidget());

    // Enter phone
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone Number'),
      '9876543210',
    );
    await tester.pump();

    // Tap Send OTP
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    verify(
      () => mockAuthBloc.add(const AuthLoginRequested('+919876543210')),
    ).called(1);
  });

  testWidgets('Enter email and submit sends AuthLoginWithMagicLinkRequested', (
    WidgetTester tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());

    await tester.pumpWidget(createWidget());

    // Switch to Email tab
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    // Enter email
    await tester.enterText(
      find.widgetWithText(TextField, 'Email Address'),
      'test@example.com',
    );
    await tester.pump();

    // Tap Send Magic Link
    await tester.tap(find.text('Send Magic Link'));
    await tester.pump();

    verify(
      () => mockAuthBloc.add(
        const AuthLoginWithMagicLinkRequested('test@example.com'),
      ),
    ).called(1);
  });

  testWidgets('Shows SnackBar on AuthError', (WidgetTester tester) async {
    whenListen(
      mockAuthBloc,
      Stream.fromIterable([AuthInitial(), const AuthError('Login Failed')]),
      initialState: AuthInitial(),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump(); // Process stream

    expect(find.text('Login Failed'), findsOneWidget);
  });

  // Navigation test requires GoRouter mocking or context mocking.
  // We used InheritedGoRouter mocking.
  testWidgets('Navigates to verify-otp on AuthOtpSent', (
    WidgetTester tester,
  ) async {
    whenListen(
      mockAuthBloc,
      Stream.fromIterable([AuthInitial(), const AuthOtpSent('+919876543210')]),
      initialState: AuthInitial(),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump();

    verify(
      () => mockGoRouter.push('/verify-otp', extra: '+919876543210'),
    ).called(1);
  });
}
