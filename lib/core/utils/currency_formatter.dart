import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats a double amount into a currency string.
  ///
  /// Uses the provided [currencySymbol] if not null, otherwise defaults to '$'.
  /// Uses the specified [locale] for formatting rules (e.g., decimal separators).
  static String format(double amount, String? currencySymbol,
      {String locale = 'en_US'}) {
    // Handle null symbol - default to '$' or maybe throw error? Defaulting is safer.
    final symbolToUse = currencySymbol ?? '\$';

    // Create a NumberFormat instance for currency.
    // Using the locale helps with correct decimal/grouping separators.
    final currencyFormat = NumberFormat.currency(
      locale: locale,
      symbol: symbolToUse, // Use the selected or default symbol
      decimalDigits: 2, // Standard 2 decimal places for currency
    );

    return currencyFormat.format(amount);
  }
}
