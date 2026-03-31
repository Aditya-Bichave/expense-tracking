import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/add_expense/domain/models/split_model.dart';

void main() {
  group('SplitType Enum Test', () {
    test('toJson returns the name of enum', () {
      expect(SplitType.PERCENT.toJson(), 'PERCENT');
      expect(SplitType.EQUAL.toJson(), 'EQUAL');
      expect(SplitType.EXACT.toJson(), 'EXACT');
      expect(SplitType.SHARE.toJson(), 'SHARE');
    });
  });

  group('SplitModel Test', () {
    test('toJson returns correctly formatted map', () {
      const split = SplitModel(
        userId: 'user_1',
        shareType: SplitType.PERCENT,
        shareValue: 50.0,
        computedAmount: 25.0,
      );
      final json = split.toJson();

      expect(json, {
        'user_id': 'user_1',
        'share_type': 'PERCENT',
        'share_value': 50.0,
        'computed_amount': 25.0,
      });
    });

    test('copyWith updates specified values and retains others', () {
      const original = SplitModel(
        userId: 'user_1',
        shareType: SplitType.PERCENT,
        shareValue: 50.0,
        computedAmount: 25.0,
      );

      final updated = original.copyWith(
        computedAmount: 30.0,
        shareType: SplitType.EXACT,
      );

      expect(updated.userId, 'user_1');
      expect(updated.shareType, SplitType.EXACT);
      expect(updated.shareValue, 50.0);
      expect(updated.computedAmount, 30.0);
    });

    test('props contain correct values for equatable', () {
      const split = SplitModel(
        userId: 'user_1',
        shareType: SplitType.PERCENT,
        shareValue: 50.0,
        computedAmount: 25.0,
      );

      expect(split.props, ['user_1', SplitType.PERCENT, 50.0, 25.0]);
    });
  });
}
