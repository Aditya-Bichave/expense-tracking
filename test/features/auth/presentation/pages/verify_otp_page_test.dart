import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/pages/verify_otp_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/pump_app.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  testWidgets('VerifyOtpPage renders correctly', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(const AuthOtpSent('1234567890'));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const VerifyOtpPage(phone: '1234567890'),
      blocProviders: [BlocProvider<AuthBloc>.value(value: mockAuthBloc)],
    );

    expect(find.text('Verify OTP'), findsOneWidget);
    expect(find.text('Enter OTP sent to 1234567890'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('VerifyOtpPage shows loading indicator when loading', (
    tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthLoading());

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const VerifyOtpPage(phone: '1234567890'),
      blocProviders: [BlocProvider<AuthBloc>.value(value: mockAuthBloc)],
      settle: false,
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('VerifyOtpPage adds AuthVerifyOtpRequested when button pressed', (
    tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(const AuthOtpSent('1234567890'));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const VerifyOtpPage(phone: '1234567890'),
      blocProviders: [BlocProvider<AuthBloc>.value(value: mockAuthBloc)],
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pump();

    verify(
      () => mockAuthBloc.add(
        const AuthVerifyOtpRequested('1234567890', '123456'),
      ),
    ).called(1);
  });
}
