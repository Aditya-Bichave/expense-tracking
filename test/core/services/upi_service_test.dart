import 'package:expense_tracker/core/services/upi_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    return true;
  }
}

class MockPlatformExceptionUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    throw PlatformException(code: 'TEST_ERROR', message: 'Test platform error');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UpiService handles PlatformException correctly', (tester) async {
    UrlLauncherPlatform.instance = MockPlatformExceptionUrlLauncher();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // Wrap with Scaffold
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpiService.launchUpiPayment(
                context: context,
                upiId: 'test@upi',
                payeeName: 'Test Payee',
                amount: 100.50,
                transactionNote: 'Test Note',
              ),
              child: const Text('Pay'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Payment Error: Test platform error'), findsOneWidget);
  });
}
