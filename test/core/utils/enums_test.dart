import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/enums.dart';

void main() {
  group('Core Enums', () {
    test('FormStatus values', () {
      expect(
        FormStatus.values,
        containsAll([
          FormStatus.initial,
          FormStatus.submitting,
          FormStatus.success,
          FormStatus.error,
        ]),
      );
    });
  });
}
