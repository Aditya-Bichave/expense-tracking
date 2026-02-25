import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class SplitEngine {
  /// Validates and calculates splits based on the strategy.
  /// Returns the reconciled list of splits.
  static List<ExpenseSplit> calculateSplits({
    required double totalAmount,
    required List<ExpenseSplit> splits,
  }) {
    // Check for total < 0
    if (totalAmount < 0)
      throw ValidationException('Total amount cannot be negative');
    if (splits.isEmpty) throw ValidationException('Splits cannot be empty');

    // Round total to 2 decimals to ensure we start clean
    final double total = _round(totalAmount);

    // Check if total is zero
    if (total == 0.0) {
      return splits.map((s) => s.copyWith(computedAmount: 0.0)).toList();
    }

    // Detect strategy from first split
    final type = splits.first.shareType;
    if (splits.any((s) => s.shareType != type)) {
      throw ValidationException('Mixed split types are not supported');
    }

    List<ExpenseSplit> calculatedSplits = [];

    switch (type) {
      case SplitType.equal:
        calculatedSplits = _calculateEqual(total, splits);
        break;
      case SplitType.exact:
        calculatedSplits = _calculateExact(total, splits);
        break;
      case SplitType.percent:
        calculatedSplits = _calculatePercent(total, splits);
        break;
      case SplitType.share:
        calculatedSplits = _calculateShare(total, splits);
        break;
    }

    // Final verification (Sanity Check)
    final sum = calculatedSplits.fold(
      0.0,
      (prev, curr) => prev + curr.computedAmount,
    );
    final diff = _round(total - sum);

    if (diff != 0.0) {
      throw ValidationException(
        'Split engine failed to reconcile: total $total vs sum $sum (diff $diff)',
      );
    }

    return calculatedSplits;
  }

  static void validatePayers({
    required double totalAmount,
    required List<ExpensePayer> payers,
  }) {
    if (payers.isEmpty) throw ValidationException('Payers cannot be empty');
    if (totalAmount < 0)
      throw ValidationException('Total amount cannot be negative');

    double sum = 0.0;
    for (var payer in payers) {
      if (payer.amountPaid < 0)
        throw ValidationException('Payer amount cannot be negative');
      sum += payer.amountPaid;
    }

    final roundedTotal = _round(totalAmount);
    final diff = _round(roundedTotal - sum);

    if (diff != 0.0) {
      throw ValidationException(
        'Payers total ($_round(sum)) does not match expense total ($roundedTotal)',
      );
    }
  }

  static List<ExpenseSplit> _calculateEqual(
    double total,
    List<ExpenseSplit> splits,
  ) {
    int count = splits.length;
    double baseAmount = _round(total / count);

    List<ExpenseSplit> result = [];
    double currentSum = 0.0;

    for (var i = 0; i < splits.length; i++) {
      result.add(splits[i].copyWith(computedAmount: baseAmount));
      currentSum += baseAmount;
    }

    double diff = _round(total - currentSum);
    if (diff != 0.0) {
      final first = result[0];
      result[0] = first.copyWith(
        computedAmount: _round(first.computedAmount + diff),
      );
    }

    return result;
  }

  static List<ExpenseSplit> _calculateExact(
    double total,
    List<ExpenseSplit> splits,
  ) {
    double sum = 0.0;
    List<ExpenseSplit> result = [];
    for (var split in splits) {
      if (split.shareValue < 0)
        throw ValidationException('Negative share value not allowed');
      double val = _round(split.shareValue);
      sum += val;
      result.add(split.copyWith(computedAmount: val));
    }

    if (_round(total - sum) != 0.0) {
      throw ValidationException(
        'Exact splits sum ($_round(sum)) does not match total ($total)',
      );
    }
    return result;
  }

  static List<ExpenseSplit> _calculatePercent(
    double total,
    List<ExpenseSplit> splits,
  ) {
    double totalPercent = 0.0;
    List<ExpenseSplit> result = [];
    double currentSum = 0.0;

    for (var split in splits) {
      if (split.shareValue < 0)
        throw ValidationException('Negative percent value not allowed');
      totalPercent += split.shareValue;

      double amount = _round((split.shareValue / 100.0) * total);
      result.add(split.copyWith(computedAmount: amount));
      currentSum += amount;
    }

    if (_round(100.0 - totalPercent) != 0.0) {
      throw ValidationException('Percentages sum ($totalPercent) must be 100');
    }

    double diff = _round(total - currentSum);
    if (diff != 0.0) {
      final first = result[0];
      result[0] = first.copyWith(
        computedAmount: _round(first.computedAmount + diff),
      );
    }

    return result;
  }

  static List<ExpenseSplit> _calculateShare(
    double total,
    List<ExpenseSplit> splits,
  ) {
    double totalShares = 0.0;
    for (var split in splits) {
      if (split.shareValue < 0)
        throw ValidationException('Negative share value not allowed');
      totalShares += split.shareValue;
    }

    if (totalShares == 0.0)
      throw ValidationException('Total shares cannot be zero');

    List<ExpenseSplit> result = [];
    double currentSum = 0.0;

    for (var split in splits) {
      double amount = _round((split.shareValue / totalShares) * total);
      result.add(split.copyWith(computedAmount: amount));
      currentSum += amount;
    }

    double diff = _round(total - currentSum);
    if (diff != 0.0) {
      final first = result[0];
      result[0] = first.copyWith(
        computedAmount: _round(first.computedAmount + diff),
      );
    }

    return result;
  }

  static double _round(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}
