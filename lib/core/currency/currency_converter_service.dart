class CurrencyConverterService {
  // A mock exchange rate table relative to USD.
  // In a real app, this would be fetched from an API (e.g., OpenExchangeRates)
  // and cached locally.
  final Map<String, double> _rates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 150.0,
    'INR': 83.0,
    'AUD': 1.53,
    'CAD': 1.35,
    'CHF': 0.9,
    'CNY': 7.23,
  };

  /// Converts an amount from one currency to another
  double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return amount;

    final fromRate = _rates[fromCurrency.toUpperCase()] ?? 1.0;
    final toRate = _rates[toCurrency.toUpperCase()] ?? 1.0;

    // Convert to base (USD) first, then to target currency
    final baseAmount = amount / fromRate;
    return baseAmount * toRate;
  }
}
