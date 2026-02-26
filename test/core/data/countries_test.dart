import 'package:expense_tracker/core/data/countries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppCountries', () {
    test('defaultCountry is US', () {
      expect(AppCountries.defaultCountry.code, 'US');
    });

    test('getCurrencyForCountry returns correct symbol', () {
      expect(AppCountries.getCurrencyForCountry('US'), r'$');
      expect(AppCountries.getCurrencyForCountry('EU'), '€');
      expect(AppCountries.getCurrencyForCountry('IN'), '₹');
    });

    test('getCurrencyForCountry returns default for null', () {
      expect(AppCountries.getCurrencyForCountry(null), r'$');
    });

    test('getCurrencyForCountry returns default for unknown code', () {
      expect(AppCountries.getCurrencyForCountry('XX'), r'$');
    });

    test('getCurrencyCodeForCountry returns correct code', () {
      expect(AppCountries.getCurrencyCodeForCountry('GB'), 'GBP');
    });

    test('findCountryByCode returns correct country', () {
      final country = AppCountries.findCountryByCode('IN');
      expect(country, isNotNull);
      expect(country!.name, 'India');
    });

    test('findCountryByCode returns null for unknown code', () {
      expect(AppCountries.findCountryByCode('XX'), isNull);
    });

    test('findCountryByCode returns null for null code', () {
      expect(AppCountries.findCountryByCode(null), isNull);
    });
  });

  group('AppCountry', () {
    test('equality works', () {
      const c1 = AppCountry(
        code: 'US',
        name: 'USA',
        currencySymbol: '\$',
        currencyCode: 'USD',
      );
      const c2 = AppCountry(
        code: 'US',
        name: 'USA',
        currencySymbol: '\$',
        currencyCode: 'USD',
      );
      const c3 = AppCountry(
        code: 'UK',
        name: 'UK',
        currencySymbol: '£',
        currencyCode: 'GBP',
      );

      expect(c1, equals(c2));
      expect(c1, isNot(equals(c3)));
    });

    test('hashCode works', () {
      const c1 = AppCountry(
        code: 'US',
        name: 'USA',
        currencySymbol: '\$',
        currencyCode: 'USD',
      );
      const c2 = AppCountry(
        code: 'US',
        name: 'USA',
        currencySymbol: '\$',
        currencyCode: 'USD',
      );
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });
}
