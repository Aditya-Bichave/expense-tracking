import 'package:expense_tracker/core/services/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SystemClock returns UTC time', () {
    final now = DateTime.now().toUtc();
    final clockNow = SystemClock().now();

    // Allow a small margin of error (milliseconds)
    expect(clockNow.difference(now).inMilliseconds.abs(), lessThan(100));
    expect(clockNow.isUtc, isTrue);
  });
}
