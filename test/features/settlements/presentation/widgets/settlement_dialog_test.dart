import 'package:expense_tracker/features/settlements/presentation/widgets/settlement_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    return true;
  }
}

void main() {
  setUp(() {
    UrlLauncherPlatform.instance = MockUrlLauncher();
  });

  testWidgets(
    'SettlementDialog shows Pay via UPI button when upiId is present',
    (tester) async {
      bool settled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettlementDialog(
              receiverName: 'Alice',
              receiverUpiId: 'alice@upi',
              amount: 500,
              currency: 'INR',
              onSettled: () => settled = true,
            ),
          ),
        ),
      );

      expect(find.text('Settle with Alice'), findsOneWidget);
      expect(find.text('500.0 INR'), findsOneWidget);
      expect(find.text('Pay via UPI'), findsOneWidget);
      expect(find.text('VPA: alice@upi'), findsOneWidget);

      // Test Mark as Paid
      await tester.tap(find.text('Mark as Paid'));
      await tester.pump();

      expect(settled, true);
    },
  );

  testWidgets(
    'SettlementDialog hides Pay via UPI button when upiId is missing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettlementDialog(
              receiverName: 'Bob',
              receiverUpiId: null,
              amount: 100,
              currency: 'USD',
              onSettled: () {},
            ),
          ),
        ),
      );

      expect(find.text('Settle with Bob'), findsOneWidget);
      expect(find.text('Pay via UPI'), findsNothing);
    },
  );
}
