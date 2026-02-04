import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats US currency correctly with default locale', () {
      final result = CurrencyFormatter.format(1234.56, '\$');
      expect(result, '\$1,234.56');
    });

    test('formats US currency correctly with explicit locale', () {
      final result = CurrencyFormatter.format(1234.56, '\$', locale: 'en_US');
      expect(result, '\$1,234.56');
    });

    test('formats Euro correctly with de_DE locale', () {
      // German uses comma as decimal separator and dot as thousands separator
      final result = CurrencyFormatter.format(1234.56, '€', locale: 'de_DE');
      // NumberFormat default placement for Euro in de_DE might be suffix or prefix depending on intl version
      // checking that it contains the parts
      expect(result, contains('1.234,56'));
      expect(result, contains('€'));
    });

    test('handles null currency symbol by defaulting to \$', () {
      final result = CurrencyFormatter.format(100.00, null);
      expect(result, '\$100.00');
    });

    test('handles empty currency symbol by defaulting to \$', () {
      final result = CurrencyFormatter.format(100.00, '');
      expect(result, '\$100.00');
    });

    test('formats large numbers correctly', () {
      final result = CurrencyFormatter.format(1000000, '¥', locale: 'ja_JP');
      expect(result, contains('1,000,000'));
    });

    test('formats zero correctly', () {
      final result = CurrencyFormatter.format(0, '\$');
      expect(result, '\$0.00');
    });

    test('formats negative numbers correctly', () {
      final result = CurrencyFormatter.format(-50.5, '\$');
      expect(result, '-\$50.50');
    });
  });
}
