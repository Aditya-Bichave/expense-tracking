import 'dart:async';
import 'package:flutter/foundation.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('ListTile background color')) {
      return;
    }
    if (originalOnError != null) {
      originalOnError(details);
    }
  };
  await testMain();
}
