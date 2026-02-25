// lib/core/data/countries.dart

// Renamed from CountryInfo to avoid conflict if imported directly elsewhere
class AppCountry {
  final String code; // e.g., 'US', 'GB', 'IN'
  final String name; // e.g., 'United States', 'United Kingdom', 'India'
  final String currencySymbol; // e.g., '$', '£', '₹'
  final String currencyCode; // e.g., 'USD', 'GBP', 'INR'

  const AppCountry({
    required this.code,
    required this.name,
    required this.currencySymbol,
    required this.currencyCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppCountry &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

abstract class AppCountries {
  static const String defaultCountryCode = 'US';

  static const List<AppCountry> availableCountries = [
    AppCountry(
      code: 'US',
      name: 'United States',
      currencySymbol: r'$',
      currencyCode: 'USD',
    ),
    AppCountry(
      code: 'GB',
      name: 'United Kingdom',
      currencySymbol: '£',
      currencyCode: 'GBP',
    ),
    AppCountry(
      code: 'EU',
      name: 'Eurozone',
      currencySymbol: '€',
      currencyCode: 'EUR',
    ),
    AppCountry(
      code: 'IN',
      name: 'India',
      currencySymbol: '₹',
      currencyCode: 'INR',
    ),
    AppCountry(
      code: 'CA',
      name: 'Canada',
      currencySymbol: r'$',
      currencyCode: 'CAD',
    ),
    AppCountry(
      code: 'AU',
      name: 'Australia',
      currencySymbol: r'$',
      currencyCode: 'AUD',
    ),
    AppCountry(
      code: 'JP',
      name: 'Japan',
      currencySymbol: '¥',
      currencyCode: 'JPY',
    ),
    AppCountry(
      code: 'CH',
      name: 'Switzerland',
      currencySymbol: 'CHF',
      currencyCode: 'CHF',
    ),
    // Add more countries as needed
  ];

  static AppCountry get defaultCountry => availableCountries.firstWhere(
    (c) => c.code == defaultCountryCode,
    orElse: () => availableCountries.first, // Absolute fallback
  );

  static String getCurrencyForCountry(String? countryCode) {
    final codeToUse = countryCode ?? defaultCountryCode;
    return availableCountries
        .firstWhere((c) => c.code == codeToUse, orElse: () => defaultCountry)
        .currencySymbol;
  }

  static String getCurrencyCodeForCountry(String? countryCode) {
    final codeToUse = countryCode ?? defaultCountryCode;
    return availableCountries
        .firstWhere((c) => c.code == codeToUse, orElse: () => defaultCountry)
        .currencyCode;
  }

  static AppCountry? findCountryByCode(String? code) {
    if (code == null) return null;
    try {
      return availableCountries.firstWhere((c) => c.code == code);
    } catch (e) {
      // Return default if not found? Or null? Returning null for now.
      return null; // Or return defaultCountry;
    }
  }
}
