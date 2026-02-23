import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/pages/verify_otp_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
}
