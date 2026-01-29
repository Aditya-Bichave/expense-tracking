import 'package:expense_tracker/core/services/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemClock', () {
    test('now returns a DateTime in UTC', () {
      final clock = SystemClock();
      final now = clock.now();
      expect(now.isUtc, isTrue);
    });

    test('now returns a recent time', () {
      final clock = SystemClock();
      final before = DateTime.now().toUtc();
      final now = clock.now();
      final after = DateTime.now().toUtc();

      expect(now.isAfter(before) || now.isAtSameMomentAs(before), isTrue);
      expect(now.isBefore(after) || now.isAtSameMomentAs(after), isTrue);
    });
  });
}
