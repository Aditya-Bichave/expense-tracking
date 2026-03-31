import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';

void main() {
  group('SimplifiedDebt Test', () {
    final tJson = {
      'from_user_id': 'u1',
      'to_user_id': 'u2',
      'amount': 50.0,
      'from_user_name': 'Alice',
      'to_user_name': 'Bob',
      'to_user_upi': 'bob@upi',
    };

    test('should parse correctly from JSON', () {
      final result = SimplifiedDebt.fromJson(tJson);

      expect(result.fromUserId, 'u1');
      expect(result.toUserId, 'u2');
      expect(result.amount, 50.0);
      expect(result.fromUserName, 'Alice');
      expect(result.toUserName, 'Bob');
      expect(result.toUserUpi, 'bob@upi');
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

      expect(debt.props, ['u1', 'u2', 50.0, 'Alice', 'Bob', 'bob@upi']);
    });
  });
}
