import 'package:expense_tracker/features/recurring_transactions/utils/weekday_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  test('weekdayNamesMonFirst returns Monday first for English', () {
    expect(weekdayNamesMonFirst('en'), [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ]);
  });

  test('weekdayNamesMonFirst localizes Arabic names', () {
    expect(weekdayNamesMonFirst('ar'), [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ]);
  });
}
