import 'dart:async';
import 'helpers/mock_helpers.dart';
import 'helpers/test_data.dart';

Future<void> testExecutable(FutureOr<void> Function() main) async {
  // Call setupFaker() here to configure the seed before any tests run.
  setupFaker();
  registerFallbackValues();

  await main();
}
