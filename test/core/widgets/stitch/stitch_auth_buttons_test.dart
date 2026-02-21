import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/widgets/stitch/stitch_auth_buttons.dart';

void main() {
  testWidgets('StitchAuthButtons renders and handles taps', (WidgetTester tester) async {
    bool phoneTapped = false;
    bool emailTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StitchAuthButtons(
            onPhoneTap: () => phoneTapped = true,
            onEmailTap: () => emailTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Continue with Phone'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);

    await tester.tap(find.text('Continue with Phone'));
    expect(phoneTapped, true);

    await tester.tap(find.text('Continue with Email'));
    expect(emailTapped, true);
  });
}
