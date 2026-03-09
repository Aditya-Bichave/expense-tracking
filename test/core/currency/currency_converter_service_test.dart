import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/currency/currency_converter_service.dart';

void main() {
  group('CurrencyConverterService', () {
    late CurrencyConverterService service;

    setUp(() {
      service = CurrencyConverterService();
    });

    test('converts between identical currencies correctly', () {
      final result = service.convert(
        amount: 100,
        fromCurrency: 'USD',
        toCurrency: 'USD',
      );
      expect(result, 100.0);
    });

    test('converts from base currency correctly', () {
      final result = service.convert(
        amount: 100,
        fromCurrency: 'USD',
        toCurrency: 'EUR',
      );
      expect(result, 92.0); // 100 * 0.92
    });

    test('converts to base currency correctly', () {
      final result = service.convert(
        amount: 92,
        fromCurrency: 'EUR',
        toCurrency: 'USD',
      );
      expect(result, closeTo(100.0, 0.01)); // 92 / 0.92 = 100
    });

    test('converts between non-base currencies correctly', () {
      final result = service.convert(
        amount: 100,
        fromCurrency: 'EUR',
        toCurrency: 'GBP',
      );
      expect(result, closeTo(85.87, 0.01));
    });
  });
}
