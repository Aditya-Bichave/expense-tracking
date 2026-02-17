import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats correctly for en_US locale with \$', () {
      final result = CurrencyFormatter.format(1234.56, '\$', locale: 'en_US');
      expect(result, '\$1,234.56');
    });

    test('formats correctly for en_US locale with €', () {
      final result = CurrencyFormatter.format(1234.56, '€', locale: 'en_US');
      expect(result, '€1,234.56');
    });

    test('formats correctly for ar locale with \$', () {
      final result = CurrencyFormatter.format(1234.56, '\$', locale: 'ar');
      expect(result, contains('\$'));
      expect(result, contains('1,234.56'));
    });

    test('handles null symbol by defaulting to \$', () {
      final result = CurrencyFormatter.format(100.0, null);
      expect(result, '\$100.00');
    });

    test('handles empty symbol by defaulting to \$', () {
      final result = CurrencyFormatter.format(100.0, '');
      expect(result, '\$100.00');
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
