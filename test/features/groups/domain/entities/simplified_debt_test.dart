import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';

void main() {
  test('SimplifiedDebt works correctly', () {
    final debt1 = SimplifiedDebt(fromUserId: 'f1', toUserId: 't1', amount: 10, fromUserName: 'User 1', toUserName: 'User 2');
    final debt2 = SimplifiedDebt(fromUserId: 'f1', toUserId: 't1', amount: 10, fromUserName: 'User 1', toUserName: 'User 2');
    final debt3 = SimplifiedDebt(fromUserId: 'f1', toUserId: 't2', amount: 10, fromUserName: 'User 1', toUserName: 'User 2');

    expect(debt1, equals(debt2));
    expect(debt1, isNot(equals(debt3)));
  });
}
