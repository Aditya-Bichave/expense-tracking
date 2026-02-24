import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final Map<String, Map<String, NumberFormat>> _cache = {};

  /// Formats a double amount into a currency string.
  ///
  /// Uses the provided [currencySymbol] if not null, otherwise defaults to '$'.
  /// Uses the specified [locale] for formatting rules (e.g., decimal separators).
  /// Defaults to 'en_US' locale.
  static String format(
    double amount,
    String? currencySymbol, {
    String locale = 'en_US',
  }) {
    // Handle null or empty symbol - default to '$'
    final symbolToUse = (currencySymbol == null || currencySymbol.isEmpty)
        ? '\$'
        : currencySymbol;

    try {
      var localeCache = _cache[locale];
      if (localeCache == null) {
        localeCache = {};
        _cache[locale] = localeCache;
      }

      var currencyFormat = localeCache[symbolToUse];
      if (currencyFormat == null) {
        currencyFormat = NumberFormat.currency(
          locale: locale,
          symbol: symbolToUse, // Use the selected or default symbol
          decimalDigits: 2, // Standard 2 decimal places for currency
        );
        localeCache[symbolToUse] = currencyFormat;
      }

      return currencyFormat.format(amount);
    } catch (e) {
      // Fallback in case of intl error (e.g., invalid locale)
      // Consider logging this error
      return "$symbolToUse${amount.toStringAsFixed(2)}";
    }
  }
}
