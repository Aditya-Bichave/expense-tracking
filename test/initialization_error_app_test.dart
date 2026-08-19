import 'dart:io';

import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late Directory tempDir;

  /// A plain ThemeData, so the widget never triggers a runtime font fetch.
  final testTheme = ThemeData(fontFamily: 'Roboto', useMaterial3: true);

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = await Directory.systemTemp.createTemp('init-error-app-test');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (
          MethodCall methodCall,
        ) async {
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// The reset deletes every `.hive`/`.lock` file in the directory it is given,
  /// so the tests inject a temp directory via [InitializationErrorApp.documentsDirectory].
  ///
  /// Mocking the `plugins.flutter.io/path_provider` channel does NOT work: on
  /// Windows and Linux path_provider is implemented against the platform APIs
  /// directly and never consults that channel, so the reset would enumerate the
  /// developer's real Documents folder and delete database files out of it.
  Future<void> pumpErrorApp(
    WidgetTester tester, {
    bool failToResolveDirectory = false,
  }) => tester.pumpWidget(
    InitializationErrorApp(
      error: HiveKeyCorruptionException('Test Corruption'),
      theme: testTheme,
      documentsDirectory: () async {
        if (failToResolveDirectory) {
          throw const FileSystemException('documents directory unavailable');
        }
        return tempDir;
      },
    ),
  );

  /// Taps reset and waits for it to finish, polling [done].
  ///
  /// The tap happens *inside* `runAsync` deliberately. The reset performs real
  /// file I/O, and a future started in the test's fake-async zone never receives
  /// those completions -- the delete would simply never happen and the assertions
  /// would fail for reasons unrelated to the widget. Driving the whole operation
  /// in the real zone is what lets dart:io make progress.
  ///
  /// Settling is not usable here either: the success SnackBar has a 5 second
  /// duration, so a timer stays pending and settling never completes.
  Future<void> tapResetAndWaitFor(
    WidgetTester tester,
    bool Function() done, {
    int maxIterations = 40,
  }) async {
    await tester.runAsync(() async {
      await tester.tap(
        find.widgetWithText(BridgeElevatedButton, 'Reset App Data'),
      );
      await tester.pump(); // shows the spinner
      for (var i = 0; i < maxIterations && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pump(); // rebuild once the reset has completed
    await tester.pump(const Duration(milliseconds: 750)); // SnackBar slides in
  }

  testWidgets('shows error message and reset button', (tester) async {
    await pumpErrorApp(tester);

    expect(
      find.textContaining('Application Initialization Failed'),
      findsOneWidget,
    );
    expect(find.textContaining('Test Corruption'), findsOneWidget);
    expect(find.text('Reset App Data'), findsOneWidget);
  });

  testWidgets('shows loading indicator when resetting', (tester) async {
    await pumpErrorApp(tester);

    final resetButton = find.widgetWithText(
      BridgeElevatedButton,
      'Reset App Data',
    );
    expect(resetButton, findsOneWidget);

    await tester.tap(resetButton);
    await tester.pump(); // Start animation

    expect(find.byType(BridgeCircularProgressIndicator), findsOneWidget);
    expect(find.text('Reset App Data'), findsNothing);
  });

  testWidgets('reset deletes database files and leaves other files alone', (
    tester,
  ) async {
    final hive = File('${tempDir.path}/expenses.hive')..writeAsStringSync('x');
    final lock = File('${tempDir.path}/expenses.lock')..writeAsStringSync('x');
    final keep = File('${tempDir.path}/notes.txt')..writeAsStringSync('x');

    await pumpErrorApp(tester);
    await tapResetAndWaitFor(
      tester,
      () => !hive.existsSync() && !lock.existsSync(),
    );

    expect(hive.existsSync(), isFalse, reason: '.hive files must be removed');
    expect(lock.existsSync(), isFalse, reason: '.lock files must be removed');
    expect(
      keep.existsSync(),
      isTrue,
      reason: 'reset must not delete unrelated files',
    );

    expect(find.textContaining('Data reset successfully'), findsOneWidget);
    // The button comes back, so a user who needs to retry can.
    expect(find.text('Reset App Data'), findsOneWidget);
  });

  testWidgets('reset reports failure instead of hanging on the spinner', (
    tester,
  ) async {
    await pumpErrorApp(tester, failToResolveDirectory: true);
    await tapResetAndWaitFor(
      tester,
      () => find.textContaining('Reset failed').evaluate().isNotEmpty,
    );

    expect(find.textContaining('Reset failed'), findsOneWidget);
    expect(find.byType(BridgeCircularProgressIndicator), findsNothing);
    expect(find.text('Reset App Data'), findsOneWidget);
  });
}
