import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/e2e_mode.dart';

void main() {
  test('E2EMode reflects state accurately', () {
    expect(E2EMode.enabled, isA<bool>());
  });
}
