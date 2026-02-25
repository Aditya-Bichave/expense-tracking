import 'package:expense_tracker/core/services/upi_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? launchedUrl;
  LaunchOptions? launchOptions;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrl = url;
    launchOptions = options;
    return true;
  }
}

class MockFailingUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  @override
  Future<bool> canLaunch(String url) async => false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockUrlLauncher mockLauncher;

  setUp(() {
    mockLauncher = MockUrlLauncher();
    UrlLauncherPlatform.instance = mockLauncher;
  });

  testWidgets('UpiService.launchUpiPayment launches correct URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
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
    );

    await tester.tap(find.text('Pay'));
    await tester.pump();

    final launchedUri = Uri.parse(mockLauncher.launchedUrl!);
    expect(launchedUri.scheme, 'upi');
    expect(launchedUri.host, 'pay');
    expect(launchedUri.queryParameters['pa'], 'test@upi');
    expect(launchedUri.queryParameters['pn'], 'Test Payee');
    expect(launchedUri.queryParameters['am'], '100.50');
    expect(launchedUri.queryParameters['cu'], 'INR');
    expect(launchedUri.queryParameters['tn'], 'Test Note');
    // Using simple int comparison or type check if enum usage is complex
    expect(
      mockLauncher.launchOptions?.mode,
      PreferredLaunchMode.externalApplication,
    );
  });

  testWidgets('UpiService shows snackbar when launch fails', (tester) async {
    // Override to return false
    UrlLauncherPlatform.instance = MockFailingUrlLauncher();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
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
    expect(find.text('No UPI app found. VPA: test@upi'), findsOneWidget);

    // Tap copy
    await tester.tap(find.text('COPY'));
    await tester.pumpAndSettle();

    expect(find.text('UPI ID copied to clipboard'), findsOneWidget);
  });
}
