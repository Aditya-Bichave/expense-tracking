import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
// Mock AuthBloc
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  setUpAll(() {
    registerFallbackValue(const AuthLoginRequested(''));
    registerFallbackValue(const AuthLoginWithMagicLinkRequested(''));
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginPage(),
      ),
    );
  }

  testWidgets('renders login page with tabs', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('submits phone login', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    // Find phone text field (first one usually or by label)
    final phoneField = find.widgetWithText(TextField, 'Phone Number');
    await tester.enterText(phoneField, '1234567890');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    verify(
      () => mockAuthBloc.add(
        any(
          that: isA<AuthLoginRequested>().having(
            (e) => e.phone,
            'phone',
            contains('1234567890'),
          ),
        ),
  testWidgets('LoginPage renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Login / Sign Up'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('Sending OTP with local number formats correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // Wait for CountryCodePicker?

    // Assuming default Country Code is +91 (from source)
    // Find phone text field. It's the one under Phone tab.
    // There are two text fields (one for email too, but it's hidden or in another tab).
    // By default Phone tab is active.

    // Enter local number
    await tester.enterText(find.byType(TextField).first, '1234567890');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    // Verify AuthLoginRequested with +911234567890
    verify(
      () => mockAuthBloc.add(
        const AuthLoginRequested('+911234567890'),
      ),
    ).called(1);
  });

  testWidgets('submits email login', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    final emailField = find.widgetWithText(TextField, 'Email Address');
    await tester.enterText(emailField, 'test@example.com');
    await tester.tap(find.text('Send Magic Link'));
    await tester.pump();

    verify(
      () => mockAuthBloc.add(
        any(
          that: isA<AuthLoginWithMagicLinkRequested>().having(
            (e) => e.email,
            'email',
            'test@example.com',
          ),
        ),
  testWidgets('Sending OTP with leading + uses input as is', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Enter number with + code
    await tester.enterText(find.byType(TextField).first, '+15551234567');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    // Verify uses input
    verify(
      () => mockAuthBloc.add(
        const AuthLoginRequested('+15551234567'),
      ),
    ).called(1);
  });

  testWidgets('shows loading indicator when state is AuthLoading', (
    tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthLoading());
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Allow StreamBuilder/BlocBuilder to emit

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.text('Send OTP'),
      findsNothing,
    ); // Button text replaced by spinner
  testWidgets('Sending OTP strips leading zero from local number', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Enter number with leading 0
    await tester.enterText(find.byType(TextField).first, '09876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    // Verify +919876543210 (strips 0)
    verify(
      () => mockAuthBloc.add(
        const AuthLoginRequested('+919876543210'),
      ),
    ).called(1);
  });
}
