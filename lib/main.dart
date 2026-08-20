import 'dart:async';

import 'package:expense_tracker/app/app.dart';
import 'package:expense_tracker/app/initialization_error_app.dart';
import 'package:expense_tracker/core/utils/app_initializer.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:flutter/material.dart';

// Re-exported so `package:expense_tracker/main.dart` stays the entrypoint's
// public surface after the split into `app/`.
export 'package:expense_tracker/app/app.dart';
export 'package:expense_tracker/app/initialization_error_app.dart';
export 'package:expense_tracker/app/root_app.dart';
export 'package:expense_tracker/core/utils/logger.dart';

void main(List<String> args) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await AppInitializer.init();
        runApp(App(args: args));
      } catch (e, stack) {
        log.severe('Initialization failed: $e\nStack: $stack');
        runApp(InitializationErrorApp(error: e));
      }
    },
    (error, stack) {
      log.severe('Unhandled error caught by zone: $error\nStack: $stack');
    },
  );
}
