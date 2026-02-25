import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseSplit', () {
    const tSplit = ExpenseSplit(
      userId: 'u1',
      shareType: SplitType.equal,
      shareValue: 1.0,
      computedAmount: 33.33,
    );

    test('supports value equality', () {
      const tSplit2 = ExpenseSplit(
        userId: 'u1',
        shareType: SplitType.equal,
        shareValue: 1.0,
        computedAmount: 33.33,
      );

      expect(tSplit, equals(tSplit2));
    });

    test('copyWith updates fields', () {
      final updated = tSplit.copyWith(
        computedAmount: 33.34,
        shareType: SplitType.percent,
      );

      expect(updated.computedAmount, 33.34);
      expect(updated.shareType, SplitType.percent);
      expect(updated.userId, tSplit.userId); // Unchanged
    });
  });
}
