import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/pages/verify_otp_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const VerifyOtpPage(phone: '1234567890'),
      ),
    );
  }

  testWidgets('VerifyOtpPage renders input and button', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Enter OTP sent to 1234567890'), findsOneWidget);
    expect(find.text('OTP'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('VerifyOtpPage calls verify on button press', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));

    verify(
      () => mockAuthBloc.add(
        const AuthVerifyOtpRequested('1234567890', '123456'),
      ),
    ).called(1);
  });

  testWidgets('shows snackbar on auth error', (tester) async {
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(const AuthError('OTP Error')));
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    expect(find.text('OTP Error'), findsOneWidget);
  });

  testWidgets('shows loading indicator when state is AuthLoading', (
    tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthLoading());
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('AppBar back button pops or goes to /login', (tester) async {
    final router = GoRouter(
      initialLocation: '/verify-otp',
      routes: [
        GoRoute(
          path: '/verify-otp',
          builder: (context, state) => BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const VerifyOtpPage(phone: '123'),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
}
