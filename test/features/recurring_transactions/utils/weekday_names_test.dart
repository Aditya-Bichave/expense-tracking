import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring_transactions/utils/weekday_names.dart';

void main() {
  group('weekdayNamesMonFirst', () {
    test('returns correct list for en_US', () {
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

    test('returns list with 7 elements', () {
      final result = weekdayNamesMonFirst('en_US');
      expect(result.length, 7);
    });

    test('starts with Monday', () {
      final result = weekdayNamesMonFirst('en_US');
      expect(result.first, 'Monday');
    });

    test('ends with Sunday', () {
      final result = weekdayNamesMonFirst('en_US');
      expect(result.last, 'Sunday');
    });

    test('contains all weekdays', () {
      final result = weekdayNamesMonFirst('en_US');
      expect(result, contains('Monday'));
      expect(result, contains('Tuesday'));
      expect(result, contains('Wednesday'));
      expect(result, contains('Thursday'));
      expect(result, contains('Friday'));
      expect(result, contains('Saturday'));
      expect(result, contains('Sunday'));
    });

    test('has correct weekday order', () {
      final result = weekdayNamesMonFirst('en_US');
      expect(result[0], 'Monday');
      expect(result[1], 'Tuesday');
      expect(result[2], 'Wednesday');
      expect(result[3], 'Thursday');
      expect(result[4], 'Friday');
      expect(result[5], 'Saturday');
      expect(result[6], 'Sunday');
    });

    test('returns non-empty strings', () {
      final result = weekdayNamesMonFirst('en_US');
      for (final day in result) {
        expect(day.isNotEmpty, true);
      }
    });

    test('handles en locale', () {
      final result = weekdayNamesMonFirst('en');
      expect(result.length, 7);
      expect(result.first, 'Monday');
      expect(result.last, 'Sunday');
    });

    test('works with different locale formats', () {
      final resultUS = weekdayNamesMonFirst('en_US');
      final resultGB = weekdayNamesMonFirst('en_GB');
      expect(resultUS.length, 7);
      expect(resultGB.length, 7);
    });

    test('reorders from Sunday-first to Monday-first', () {
      // This test verifies the function's core purpose:
      // transforming Sunday-first (intl default) to Monday-first
      final result = weekdayNamesMonFirst('en_US');
      expect(result.indexOf('Monday'), 0);
      expect(result.indexOf('Sunday'), 6);
    });
  });
}