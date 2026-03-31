import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_balances.dart';
import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';

void main() {
  group('GroupBalances Test', () {
    final tJson = {
      'my_net_balance': 100.0,
      'simplified_debts': [
        {
          'from_user_id': 'u1',
          'to_user_id': 'u2',
          'amount': 50.0,
          'from_user_name': 'Alice',
          'to_user_name': 'Bob',
          'to_user_upi': 'bob@upi',
        },
      ],
    };

    test('should parse correctly from JSON', () {
      final result = GroupBalances.fromJson(tJson);

      expect(result.myNetBalance, 100.0);
      expect(result.simplifiedDebts.length, 1);
      expect(result.simplifiedDebts[0].amount, 50.0);
    });

    test('should handle missing simplified debts gracefully', () {
      final jsonNoDebts = {'my_net_balance': -50.0};

      final result = GroupBalances.fromJson(jsonNoDebts);

      expect(result.myNetBalance, -50.0);
      expect(result.simplifiedDebts.isEmpty, true);
    });

    test('props should contain all fields', () {
      const debt = SimplifiedDebt(
        fromUserId: 'u1',
        toUserId: 'u2',
        amount: 50.0,
        fromUserName: 'Alice',
        toUserName: 'Bob',
        toUserUpi: 'bob@upi',
      );

      const balances = GroupBalances(
        myNetBalance: 100.0,
        simplifiedDebts: [debt],
      );

      expect(balances.props, [
        100.0,
        [debt],
      ]);
    });
  });
}
