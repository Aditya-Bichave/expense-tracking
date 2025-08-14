import 'package:expense_tracker/core/utils/currency_parser.dart';
// ignore: depend_on_referenced_packages
import 'package:test/test.dart';

void main() {
  group('parseCurrency', () {
    test('parses US formatted numbers', () {
      final result = parseCurrency('1,234.56', 'en_US');
      expect(result, closeTo(1234.56, 0.001));
    });

    test('parses German formatted numbers', () {
      final result = parseCurrency('1.234,56', 'de_DE');
      expect(result, closeTo(1234.56, 0.001));
    });

    test('parses numbers when locale is a country code', () {
      final result = parseCurrency('3000', 'US');
      expect(result, 3000);
    });

    test('returns NaN for invalid input', () {
      final result = parseCurrency('abc', 'en_US');
      expect(result.isNaN, isTrue);
    });
  });
}
