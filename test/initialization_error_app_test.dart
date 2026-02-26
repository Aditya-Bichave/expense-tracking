import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '.';
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('InitializationErrorApp shows error message and reset button', (WidgetTester tester) async {
    final exception = HiveKeyCorruptionException("Test Corruption");

    // Inject a basic theme to avoid GoogleFonts issues
    final testTheme = ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
    );

    await tester.pumpWidget(InitializationErrorApp(
      error: exception,
      theme: testTheme,
    ));

    expect(find.textContaining("Application Initialization Failed"), findsOneWidget);
    expect(find.textContaining("Test Corruption"), findsOneWidget);
    expect(find.text("Reset App Data"), findsOneWidget);
  });

  testWidgets('InitializationErrorApp shows loading indicator when resetting', (WidgetTester tester) async {
    final exception = HiveKeyCorruptionException("Test Corruption");
    final testTheme = ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
    );

    await tester.pumpWidget(InitializationErrorApp(
      error: exception,
      theme: testTheme,
    ));

    final resetButton = find.widgetWithText(ElevatedButton, "Reset App Data");
    expect(resetButton, findsOneWidget);

    await tester.tap(resetButton);
    await tester.pump(); // Start animation

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Reset App Data"), findsNothing);
  });
}
