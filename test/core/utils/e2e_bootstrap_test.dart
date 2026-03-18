import 'package:expense_tracker/core/utils/e2e_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('E2eBootstrap works', () {
    expect(E2EMode.enabled, isFalse);
  });
}
