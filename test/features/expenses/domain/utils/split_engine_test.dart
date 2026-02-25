import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:expense_tracker/features/expenses/domain/utils/split_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitEngine', () {
    test('EQUAL splits: 100 / 3', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'C',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
      ];
      final result = SplitEngine.calculateSplits(
        totalAmount: 100.00,
        splits: splits,
      );

      expect(result[0].computedAmount, 33.34); // Remainder assigned to first
      expect(result[1].computedAmount, 33.33);
      expect(result[2].computedAmount, 33.33);
      expect(result.fold(0.0, (sum, s) => sum + s.computedAmount), 100.00);
    });

    test('EQUAL splits: 10 / 3', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'C',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
      ];
      final result = SplitEngine.calculateSplits(
        totalAmount: 10.00,
        splits: splits,
      );

      expect(result[0].computedAmount, 3.34);
      expect(result[1].computedAmount, 3.33);
      expect(result[2].computedAmount, 3.33);
    });

    test('EQUAL splits: 0.01 / 2', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
      ];
      final result = SplitEngine.calculateSplits(
        totalAmount: 0.01,
        splits: splits,
      );

      expect(result[0].computedAmount, 0.00);
      expect(result[1].computedAmount, 0.01);
    });

    test('EXACT splits: exact match', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.exact,
          shareValue: 50.00,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.exact,
          shareValue: 50.00,
          computedAmount: 0,
        ),
      ];
      final result = SplitEngine.calculateSplits(
        totalAmount: 100.00,
        splits: splits,
      );

      expect(result[0].computedAmount, 50.00);
      expect(result[1].computedAmount, 50.00);
    });

    test('EXACT splits: mismatch throws exception', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.exact,
          shareValue: 50.00,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.exact,
          shareValue: 40.00,
          computedAmount: 0,
        ),
      ];
      expect(
        () => SplitEngine.calculateSplits(totalAmount: 100.00, splits: splits),
        throwsA(isA<ValidationException>()),
      );
    });

    test('PERCENT splits: 40% + 60% of 100', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.percent,
          shareValue: 40,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.percent,
          shareValue: 60,
          computedAmount: 0,
        ),
      ];
      final result = SplitEngine.calculateSplits(
        totalAmount: 100.00,
        splits: splits,
      );

      expect(result[0].computedAmount, 40.00);
      expect(result[1].computedAmount, 60.00);
    });

    test('PERCENT splits: rounding 33.33% of 100', () {
      // 33.33 + 33.33 + 33.34 = 100%
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.percent,
          shareValue: 33.33,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.percent,
          shareValue: 33.33,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'C',
          shareType: SplitType.percent,
          shareValue: 33.34,
          computedAmount: 0,
        ),
      ];
      final result = SplitEngine.calculateSplits(
        totalAmount: 100.00,
        splits: splits,
      );

      // 33.33% of 100 is 33.33. Sum is 99.99 + 0.01 (last one is 33.34 so it is 33.34)
      // Wait: 33.33 * 100 / 100 = 33.33.
      // 33.34 * 100 / 100 = 33.34.
      // Sum = 100.00. No remainder needed.
      expect(result[0].computedAmount, 33.33);
      expect(result[1].computedAmount, 33.33);
      expect(result[2].computedAmount, 33.34);
    });

    test('PERCENT splits: not 100% throws', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.percent,
          shareValue: 40,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.percent,
          shareValue: 40,
          computedAmount: 0,
        ),
      ];
      expect(
        () => SplitEngine.calculateSplits(totalAmount: 100.00, splits: splits),
        throwsA(isA<ValidationException>()),
      );
    });

    test('SHARE splits: 2 shares + 1 share of 100', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.share,
          shareValue: 2,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.share,
          shareValue: 1,
          computedAmount: 0,
        ),
      ];
      final result = SplitEngine.calculateSplits(
        totalAmount: 100.00,
        splits: splits,
      );

      // Total shares = 3.
      // A: 2/3 * 100 = 66.666... -> 66.67
      // B: 1/3 * 100 = 33.333... -> 33.33
      // Sum: 100.00.

      // Let's check with engine logic:
      // A: round(66.666) = 66.67
      // B: round(33.333) = 33.33
      // Sum = 100.00. Diff 0.

      expect(result[0].computedAmount, 66.67);
      expect(result[1].computedAmount, 33.33);
    });

    test('SHARE splits: 1 share each (like equal) of 100', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.share,
          shareValue: 1,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.share,
          shareValue: 1,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'C',
          shareType: SplitType.share,
          shareValue: 1,
          computedAmount: 0,
        ),
      ];
      final result = SplitEngine.calculateSplits(
        totalAmount: 100.00,
        splits: splits,
      );

      // 100/3 = 33.33. Remainder 0.01 to first.
      expect(result[0].computedAmount, 33.34);
      expect(result[1].computedAmount, 33.33);
      expect(result[2].computedAmount, 33.33);
    });

    test('Mixed split types throws', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
        const ExpenseSplit(
          userId: 'B',
          shareType: SplitType.percent,
          shareValue: 50,
          computedAmount: 0,
        ),
      ];
      expect(
        () => SplitEngine.calculateSplits(totalAmount: 100.00, splits: splits),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Zero total returns zero splits', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
      ];
      final result = SplitEngine.calculateSplits(
        totalAmount: 0.00,
        splits: splits,
      );
      expect(result[0].computedAmount, 0.00);
    });

    test('Negative total throws', () {
      final splits = [
        const ExpenseSplit(
          userId: 'A',
          shareType: SplitType.equal,
          shareValue: 1,
          computedAmount: 0,
        ),
      ];
      expect(
        () => SplitEngine.calculateSplits(totalAmount: -10.00, splits: splits),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Validate Payers: Success', () {
      final payers = [
        const ExpensePayer(userId: 'A', amountPaid: 80.00),
        const ExpensePayer(userId: 'B', amountPaid: 20.00),
      ];
      expect(
        () => SplitEngine.validatePayers(totalAmount: 100.00, payers: payers),
        returnsNormally,
      );
    });

    test('Validate Payers: Mismatch throws', () {
      final payers = [
        const ExpensePayer(userId: 'A', amountPaid: 80.00),
        const ExpensePayer(userId: 'B', amountPaid: 10.00),
      ];
      expect(
        () => SplitEngine.validatePayers(totalAmount: 100.00, payers: payers),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
