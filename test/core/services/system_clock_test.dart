import 'package:expense_tracker/core/services/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SystemClock returns UTC time', () {
    final clock = SystemClock();
    final now = clock.now();
    expect(now.isUtc, isTrue);
  });
}
