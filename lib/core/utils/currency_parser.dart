import 'package:intl/intl.dart';

/// Parses a currency [value] string according to the given [locale].
/// Returns [double.nan] if parsing fails.
double parseCurrency(String value, String locale) {
  final normalized = _normalizeLocale(locale);
  try {
    final formatter = NumberFormat.currency(locale: normalized);
    final number = formatter.parse(value);
    return number.toDouble();
  } catch (_) {
    try {
      // Fallback to decimal pattern if currency fails
      final formatter = NumberFormat.decimalPattern(normalized);
      final number = formatter.parse(value);
      return number.toDouble();
    } catch (_) {
      // Last resort: attempt a basic parse after removing non-numeric chars
      // We assume standard format if intl fails: remove commas (common grouping), keep dot
      // This is a naive fallback but better than nothing for simple inputs
      final sanitized = value.replaceAll(',', '');
      // If it still has characters like currency symbols, strip them?
      // The previous regex `[^0-9-.,]` kept dots and commas.
      // Now we stripped commas.
      // Use regex to strip everything except digits, dots, minus.
      final clean = sanitized.replaceAll(RegExp('[^0-9-.]'), '');
      return double.tryParse(clean) ?? double.nan;
    }
  }
}

/// Normalizes a [locale] string by converting a standalone country code (e.g. `US`)
/// into a valid locale such as `en_US`. If a language is already provided, it is
/// returned unchanged.
String _normalizeLocale(String locale) {
  if (locale.isEmpty) return 'en_US';
  if (!locale.contains('_') && locale.length == 2) {
    return 'en_${locale.toUpperCase()}';
  }
  return locale;
}
