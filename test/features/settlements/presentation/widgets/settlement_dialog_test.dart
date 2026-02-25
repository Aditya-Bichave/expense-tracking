import 'package:expense_tracker/features/settlements/presentation/widgets/settlement_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart'; // For LinkDelegate if needed
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncher extends UrlLauncherPlatform {
  String? launchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrl = url;
    return true;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
}

void main() {
  late MockUrlLauncher mockLauncher;

  setUp(() {
    mockLauncher = MockUrlLauncher();
    UrlLauncherPlatform.instance = mockLauncher;
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

  testWidgets(
    'Tapping Pay via UPI launches URL and shows confirmation dialog',
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

      // Tap Pay via UPI
      await tester.tap(find.text('Pay via UPI'));
      await tester.pump(); // Launch URL
      await tester.pumpAndSettle(); // Wait for dialog

      // Verify URL was launched
      expect(mockLauncher.launchedUrl, isNotNull);
      expect(mockLauncher.launchedUrl, contains('upi://pay'));
      expect(mockLauncher.launchedUrl, contains('pa=alice@upi'));

      // Verify Confirmation Dialog
      expect(find.text('Payment Successful?'), findsOneWidget);
      expect(find.text('Yes, Record Settlement'), findsOneWidget);
      expect(find.text('Not yet'), findsOneWidget);

      // Tap Yes
      await tester.tap(find.text('Yes, Record Settlement'));
      await tester.pump();

      expect(settled, true);
    },
  );
}
