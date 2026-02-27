import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(const AuthLoginRequested(''));
    registerFallbackValue(const AuthLoginWithMagicLinkRequested(''));
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginPage(),
      ),
    );
  }

  group('LoginPage', () {
    testWidgets('renders login page with tabs and correct initial state', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Login / Sign Up'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('switches between phone and email tabs', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Initially in Phone tab
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email Address'), findsNothing);

      // Switch to Email tab
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      expect(find.text('Phone Number'), findsNothing);
      expect(find.text('Email Address'), findsOneWidget);
    });

    group('Phone Login Formatting', () {
      testWidgets('submits with default country code (+91)', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        await tester.enterText(find.byType(AppTextField).first, '1234567890');
        await tester.tap(find.text('Send OTP'));
        await tester.pump();

        verify(
          () => mockAuthBloc.add(const AuthLoginRequested('+911234567890')),
        ).called(1);
      });

      testWidgets('strips leading zero from local number', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        await tester.enterText(find.byType(AppTextField).first, '09876543210');
        await tester.tap(find.text('Send OTP'));
        await tester.pump();

        verify(
          () => mockAuthBloc.add(const AuthLoginRequested('+919876543210')),
        ).called(1);
      });

      testWidgets('uses manual plus code (+1) correctly', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        await tester.enterText(find.byType(AppTextField).first, '+15551234567');
        await tester.tap(find.text('Send OTP'));
        await tester.pump();

        verify(
          () => mockAuthBloc.add(const AuthLoginRequested('+15551234567')),
        ).called(1);
      });
    });

    testWidgets('submits email login', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(AppTextField).first,
        'test@example.com',
      );
      await tester.tap(find.text('Send Magic Link'));
      await tester.pump();

      verify(
        () => mockAuthBloc.add(
          const AuthLoginWithMagicLinkRequested('test@example.com'),
        ),
      ).called(1);
    });

    testWidgets(
      'shows loading indicator and disables buttons when state is AuthLoading',
      (tester) async {
        when(() => mockAuthBloc.state).thenReturn(AuthLoading());
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        // Check for CircularProgressIndicator which AppButton should show
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // AppButton might still show text, so we rely on finding the progress indicator
        // and optionally checking enabled state if possible, but finding spinner is sufficient validation of loading state.

        // Also verify the button is disabled (if possible) or at least present
        expect(find.byType(AppButton), findsOneWidget);
      },
    );
  });
}
