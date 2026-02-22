import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers/mock_helpers.dart';
import 'helpers/test_data.dart';

Future<void> testExecutable(FutureOr<void> Function() main) async {
  // Call setupFaker() here to configure the seed before any tests run.
  setupFaker();
  registerFallbackValues();

  // Prevent GoogleFonts from making network requests during tests
  GoogleFonts.config.allowRuntimeFetching = false;

  await main();
}
