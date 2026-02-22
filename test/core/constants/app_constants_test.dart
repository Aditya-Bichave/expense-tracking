import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

void main() {
  test('AppConstants values are correct', () {
    expect(AppConstants.appName, 'Spend Savvy');
  });
}
