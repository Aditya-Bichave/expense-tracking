import 'dart:convert';

import 'package:expense_tracker/core/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:simple_logger/simple_logger.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('/log'));
  });

  tearDown(() {
    debugLogClient = null;
  });

  test('Logger initializes correctly', () {
    expect(log, isNotNull);
    expect(log, isA<SimpleLogger>());
  });

  test('sendToServer sends POST request with correct data', () async {
    final mockClient = MockHttpClient();
    debugLogClient = mockClient;

    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{"ok":true}', 200));

    final info = LogInfo(
      level: Level.INFO,
      message: 'Test message',
      time: DateTime.now(),
      stackTrace: StackTrace.empty,
    );

    // Act
    await sendToServer(info);

    // Assert
    verify(() => mockClient.post(
          Uri.parse('/log'),
          headers: {'Content-Type': 'application/json'},
          body: any(named: 'body', that: contains('Test message')),
        )).called(1);
  });

  test('sendToServer throttles requests', () async {
    final mockClient = MockHttpClient();
    debugLogClient = mockClient;

    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{"ok":true}', 200));

    final info = LogInfo(
      level: Level.INFO,
      message: 'Test message',
      time: DateTime.now(),
    );

    // Act
    // First call might be throttled if run immediately after previous test due to static _lastLogTime
    // So we wait a bit to ensure it can run
    await Future.delayed(const Duration(milliseconds: 150));
    await sendToServer(info); // Should be Allowed

    // These should be throttled
    await sendToServer(info);
    await sendToServer(info);

    // Assert
    // Should be called only once
    verify(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .called(1);
  });
}
