import 'package:expense_tracker/features/settlements/domain/entities/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tSettlement = Settlement(
    id: '1',
    groupId: 'group1',
    fromUserId: 'user1',
    toUserId: 'user2',
    amount: 100.0,
    currency: 'USD',
    createdAt: DateTime(2023, 10, 1),
  );

  test('should be a subclass of Equatable', () async {
    expect(tSettlement, isA<Settlement>());
  });

  test('should support value equality', () async {
    final tSettlement2 = Settlement(
      id: '1',
      groupId: 'group1',
      fromUserId: 'user1',
      toUserId: 'user2',
      amount: 100.0,
      currency: 'USD',
      createdAt: DateTime(2023, 10, 1),
    );
    expect(tSettlement, equals(tSettlement2));
  });

  test('props should contain all fields', () async {
    expect(tSettlement.props, [
      '1',
      'group1',
      'user1',
      'user2',
      100.0,
      'USD',
      DateTime(2023, 10, 1),
    ]);
  });
}
