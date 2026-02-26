// ignore_for_file: directives_ordering

import 'dart:convert';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:simple_logger/simple_logger.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('Logger', () {
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      debugLogClient = mockClient; // Inject mock client
    });

    tearDown(() {
      debugLogClient = null;
    });

    test('Logger initializes correctly', () {
      expect(log, isNotNull);
    });

    test('sendToServer sends POST request with correct data', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('OK', 200));

      final info = LogInfo(
        level: Level.INFO,
        message: 'Test message',
        time: DateTime.now(),
        // callerFrame: null, // Optional, skipping to avoid package:stack_trace dependency issues in test
        stackTrace: StackTrace.current,
      );

      // We need to wait slightly to avoid throttle from previous tests if run in suite
      await Future.delayed(const Duration(milliseconds: 200));

      await sendToServer(info, endpoint: 'http://test.com/log');

      verify(
        () => mockClient.post(
          Uri.parse('http://test.com/log'),
          headers: {'Content-Type': 'application/json'},
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('sendToServer throttles requests', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('OK', 200));

      final info = LogInfo(
        level: Level.INFO,
        message: 'Test',
        time: DateTime.now(),
      );

      // Wait to clear previous throttle
      await Future.delayed(const Duration(milliseconds: 200));

      // First call
      await sendToServer(info);
      // Immediate second call
      await sendToServer(info);

      // Should be called once due to 100ms throttle
      verify(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });
  });
}
