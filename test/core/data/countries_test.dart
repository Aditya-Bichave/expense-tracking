import 'package:expense_tracker/core/data/countries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppCountries', () {
    test('defaultCountry is US', () {
      expect(AppCountries.defaultCountry.code, 'US');
      expect(AppCountries.defaultCountry.currencySymbol, r'$');
    });

    test('getCurrencyForCountry returns correct symbol', () {
      expect(AppCountries.getCurrencyForCountry('US'), r'$');
      expect(AppCountries.getCurrencyForCountry('GB'), '£');
      expect(AppCountries.getCurrencyForCountry('EU'), '€');
      expect(AppCountries.getCurrencyForCountry('IN'), '₹');
      expect(AppCountries.getCurrencyForCountry('JP'), '¥');
    });

    test('getCurrencyCodeForCountry returns correct code', () {
      expect(AppCountries.getCurrencyCodeForCountry('US'), 'USD');
      expect(AppCountries.getCurrencyCodeForCountry('GB'), 'GBP');
      expect(AppCountries.getCurrencyCodeForCountry('EU'), 'EUR');
      expect(AppCountries.getCurrencyCodeForCountry('IN'), 'INR');
    });

    test('getCurrencyForCountry returns default for null', () {
      expect(AppCountries.getCurrencyForCountry(null), r'$');
    });

    test('getCurrencyForCountry returns default for unknown code', () {
      expect(AppCountries.getCurrencyForCountry('XX'), r'$');
    });

    test('findCountryByCode returns correct country', () {
      final country = AppCountries.findCountryByCode('IN');
      expect(country, isNotNull);
      expect(country!.name, 'India');
    });

    test('findCountryByCode returns null for unknown code', () {
      final country = AppCountries.findCountryByCode('XX');
      expect(country, isNull);
    });

    test('findCountryByCode returns null for null code', () {
      final country = AppCountries.findCountryByCode(null);
      expect(country, isNull);
    });
  });

  group('AppCountry', () {
    test('equality works', () {
      const country1 = AppCountry(
        code: 'US',
        name: 'United States',
        currencySymbol: r'$',
        currencyCode: 'USD',
      );
      const country2 = AppCountry(
        code: 'US',
        name: 'United States',
        currencySymbol: r'$',
        currencyCode: 'USD',
      );
      const country3 = AppCountry(
        code: 'GB',
        name: 'United Kingdom',
        currencySymbol: '£',
        currencyCode: 'GBP',
      );

      expect(country1, equals(country2));
      expect(country1, isNot(equals(country3)));
    });

    test('hashCode works', () {
      const country1 = AppCountry(
        code: 'US',
        name: 'United States',
        currencySymbol: r'$',
        currencyCode: 'USD',
      );
      const country2 = AppCountry(
        code: 'US',
        name: 'United States',
        currencySymbol: r'$',
        currencyCode: 'USD',
      );

      expect(country1.hashCode, equals(country2.hashCode));
    });
  });
}
