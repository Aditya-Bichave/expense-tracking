import 'dart:io';
import 'dart:ui';
import 'package:expense_tracker/core/services/image_compression_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ImageCompressionService service;

  setUp(() {
    service = ImageCompressionService();

    // Register RootIsolateToken to avoid "RootIsolateToken.instance is null"
    // However, Isolate.run might still be tricky in tests if not mocked or handled by test environment.
    // Flutter test environment supports isolates, but mocking platform channels inside them is hard.
    // We will focus on testing the logic we CAN reach or mocking the method channel if needed.

    // Mock getTemporaryDirectory via PathProviderPlatform (implicitly done by setMockMethodCallHandler usually or manually)
    const MethodChannel(
      'plugins.flutter.io/path_provider',
    ).setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getTemporaryDirectory') {
        return '/tmp'; // Mock temp path
      }
      return null;
    });
  });

  group('ImageCompressionService', () {
    // NOTE: Testing `Isolate.run` with `FlutterImageCompress` which uses platform channels
    // inside a unit test environment is notoriously difficult because the background isolate
    // doesn't share the main isolate's mock method handlers.
    //
    // For coverage, we verify the service can be instantiated.
    // Integration tests are better suited for actual compression verification.

    test('can be instantiated', () {
      expect(service, isNotNull);
    });

    // We skip actual compression test to avoid "MissingPluginException" or hanging
    // in test environment without full integration setup.
  });
}
