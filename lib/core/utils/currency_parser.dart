import 'package:intl/intl.dart';

/// Parses a currency [value] string according to the given [locale].
/// Returns [double.nan] if parsing fails.
double parseCurrency(String value, String locale) {
  try {
    final formatter = NumberFormat.currency(locale: locale);
    final number = formatter.parse(value);
    return number.toDouble();
  } catch (_) {
    try {
      // Fallback to decimal pattern if currency fails
      final formatter = NumberFormat.decimalPattern(locale);
      final number = formatter.parse(value);
      return number.toDouble();
    } catch (_) {
      return double.nan;
    }
  }
}
