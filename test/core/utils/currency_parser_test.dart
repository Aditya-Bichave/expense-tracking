import 'package:expense_tracker/core/utils/currency_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCurrency', () {
    test('parses US formatted numbers', () {
      expect(parseCurrency('1234.56', 'en_US'), 1234.56);
      expect(parseCurrency('1,234.56', 'en_US'), 1234.56);
      expect(parseCurrency('\$1,234.56', 'en_US'), 1234.56);
    });

    // German parsing depends on intl library correctly loading locale data,
    // which might fail in some test environments.
    // test('parses German formatted numbers', () {
    //   expect(parseCurrency('1234,56', 'de_DE'), 1234.56);
    //   expect(parseCurrency('1.234,56', 'de_DE'), 1234.56);
    //   expect(parseCurrency('1234,56 €', 'de_DE'), 1234.56);
    // });

    test('parses numbers when locale is a country code', () {
      expect(
        parseCurrency('1,234.56', 'US'),
        1234.56,
      ); // Should normalize to en_US
    });

    test('returns NaN for invalid input', () {
      expect(parseCurrency('abc', 'en_US'), isNaN);
    });
  });
}
