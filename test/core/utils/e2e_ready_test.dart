import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/e2e_ready.dart';

void main() {
  test('signalE2EReady executes without throwing on this platform', () {
    expect(() => signalE2EReady(), returnsNormally);
  });
}
