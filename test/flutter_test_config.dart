import 'dart:async';
import 'helpers/test_data.dart'; // Import your helper

Future<void> testExecutable(FutureOr<void> Function() main) async {
  // Call setupFaker() here to configure the seed before any tests run.
  setupFaker();

  await main();
}
