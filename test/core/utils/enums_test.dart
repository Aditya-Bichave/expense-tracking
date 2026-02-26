import 'package:expense_tracker/core/utils/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Enums', () {
    test('FormStatus values', () {
      expect(FormStatus.values.length, 4);
      expect(FormStatus.initial.index, 0);
      expect(FormStatus.submitting.index, 1);
      expect(FormStatus.success.index, 2);
      expect(FormStatus.error.index, 3);
    });
  });
}
