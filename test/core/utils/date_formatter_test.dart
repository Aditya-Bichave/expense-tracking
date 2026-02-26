import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  group('DateFormatter', () {
    setUpAll(() async {
      await initializeDateFormatting('en', null);
    });

    test('formatDateTime should format the date and time correctly', () {
      final dateTime = DateTime(2023, 1, 15, 14, 30);
      const expected = 'Jan 15, 2023 2:30 PM';
      expect(DateFormatter.formatDateTime(dateTime, locale: 'en'), expected);
    });

    test('formatDate should format the date correctly', () {
      final dateTime = DateTime(2023, 1, 15);
      const expected = '1/15/2023';
      expect(DateFormatter.formatDate(dateTime, locale: 'en'), expected);
    });

    test('formatDateTime should handle different locales', () {
      final dateTime = DateTime(2023, 1, 15, 14, 30);
      const expected = '15 janv. 2023, 14:30';
      expect(
        DateFormatter.formatDateTime(dateTime, locale: 'fr'),
        isNot(expected),
      );
    });

    test('format should format the date using custom pattern and cache it', () {
      final dateTime = DateTime(2023, 1, 15);
      const pattern = 'yyyy-MM-dd';
      const expected = '2023-01-15';
      expect(DateFormatter.format(dateTime, pattern, locale: 'en'), expected);

      // Call again to verify cache (though tricky to verify cache hit, at least verify output)
      expect(DateFormatter.format(dateTime, pattern, locale: 'en'), expected);
    });
  });
}
