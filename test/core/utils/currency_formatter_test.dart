import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter', () {
    test('format should format currency with default locale and symbol', () {
      final result = CurrencyFormatter.format(1234.56, null);
      // Default locale is en_US, symbol default is $
      expect(result, '\$1,234.56');
    });

    test('format should use provided currency symbol', () {
      final result = CurrencyFormatter.format(1234.56, '€');
      expect(result, '€1,234.56');
    });

    test('format should handle different locales', () {
      // German uses comma for decimal, dot for thousands
      // Note: non-breaking space might be used between symbol and number in some locales
      final result = CurrencyFormatter.format(1234.56, '€', locale: 'de_DE');
      // "1.234,56 €" or "€ 1.234,56" depending on implementation of NumberFormat.currency
      // The implementation passes 'symbol' to NumberFormat.currency.
      // Let's check loose containment to be safe with spaces
      expect(result, contains('1.234,56'));
      expect(result, contains('€'));
    });

    test('format should fallback when locale is invalid', () {
      // 'invalid_locale' might throw or fall back within NumberFormat.
      // If NumberFormat throws, our catch block catches it.
      // If NumberFormat handles it gracefully, we might need a way to force an error.
      // Intentionally passing a completely bogus locale.
      final result =
          CurrencyFormatter.format(1234.56, '\$', locale: 'invalid_LOCALE_!@#');

      // We assert that it returns a non-empty string that contains the symbol and part of the number.
      // Whether it falls back to default formatting or the catch block, it should produce a readable result.
      expect(result, contains('\$'));
      expect(result, contains('34.56')); // Decimal part should always be there
    });
  });
}
