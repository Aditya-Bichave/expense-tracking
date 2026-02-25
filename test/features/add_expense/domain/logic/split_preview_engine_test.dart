import 'package:expense_tracker/features/add_expense/domain/logic/split_preview_engine.dart';
import 'package:expense_tracker/features/add_expense/domain/models/split_model.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitPreviewEngine', () {
    test(
      'calculateEqualSplits distributes remainder correctly (10.00 / 3)',
      () {
        final members = [
          GroupMember(
            id: '1',
            groupId: 'g1',
            userId: 'u1',
            role: GroupRole.member,
            joinedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: '2',
            groupId: 'g1',
            userId: 'u2',
            role: GroupRole.member,
            joinedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: '3',
            groupId: 'g1',
            userId: 'u3',
            role: GroupRole.member,
            joinedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final splits = SplitPreviewEngine.calculateEqualSplits(10.00, members);

        expect(splits.length, 3);
        // 10.00 -> 1000 cents. 1000 / 3 = 333 remainder 1.
        // So first gets 3.34, others 3.33.
        expect(splits[0].computedAmount, 3.34);
        expect(splits[1].computedAmount, 3.33);
        expect(splits[2].computedAmount, 3.33);

        final total = splits.fold(0.0, (sum, s) => sum + s.computedAmount);
        expect(total, 10.00);
      },
    );

    test('validatePercent checks sum == 100', () {
      final validSplits = [
        SplitModel(
          userId: 'u1',
          shareType: SplitType.PERCENT,
          shareValue: 40,
          computedAmount: 40,
        ),
        SplitModel(
          userId: 'u2',
          shareType: SplitType.PERCENT,
          shareValue: 60,
          computedAmount: 60,
        ),
      ];
      expect(SplitPreviewEngine.validatePercent(validSplits), true);

      final invalidSplits = [
        SplitModel(
          userId: 'u1',
          shareType: SplitType.PERCENT,
          shareValue: 40,
          computedAmount: 40,
        ),
        SplitModel(
          userId: 'u2',
          shareType: SplitType.PERCENT,
          shareValue: 50,
          computedAmount: 50,
        ),
      ];
      expect(SplitPreviewEngine.validatePercent(invalidSplits), false);
    });

    test('validateExact checks sum == total', () {
      final splits = [
        SplitModel(
          userId: 'u1',
          shareType: SplitType.EXACT,
          shareValue: 10,
          computedAmount: 10,
        ),
        SplitModel(
          userId: 'u2',
          shareType: SplitType.EXACT,
          shareValue: 20,
          computedAmount: 20,
        ),
      ];
      expect(SplitPreviewEngine.validateExact(splits, 30.0), true);
      expect(SplitPreviewEngine.validateExact(splits, 40.0), false);
    });
  });
}
