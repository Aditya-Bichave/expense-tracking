import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring_transactions/utils/weekday_names.dart';

void main() {
  test('weekdayNamesMonFirst returns correct list for en_US', () {
    final result = weekdayNamesMonFirst('en_US');
    expect(result, [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ]);
  });
}
