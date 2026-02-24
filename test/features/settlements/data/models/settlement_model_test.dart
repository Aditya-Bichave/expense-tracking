import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:expense_tracker/features/settlements/domain/entities/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tSettlementModel = SettlementModel(
    id: '1',
    groupId: 'group1',
    fromUserId: 'user1',
    toUserId: 'user2',
    amount: 100.0,
    currency: 'USD',
    createdAt: DateTime(2023, 10, 1),
  );

  final tSettlement = Settlement(
    id: '1',
    groupId: 'group1',
    fromUserId: 'user1',
    toUserId: 'user2',
    amount: 100.0,
    currency: 'USD',
    createdAt: DateTime(2023, 10, 1),
  );

  test('should convert to Settlement entity', () {
    final result = tSettlementModel.toEntity();
    expect(result, isA<Settlement>());
    expect(result, equals(tSettlement));
  });

  group('fromEntity', () {
    test('should return a valid SettlementModel from entity', () {
      final result = SettlementModel.fromEntity(tSettlement);
      expect(result.id, tSettlement.id);
      expect(result.groupId, tSettlement.groupId);
      expect(result.fromUserId, tSettlement.fromUserId);
      expect(result.toUserId, tSettlement.toUserId);
      expect(result.amount, tSettlement.amount);
      expect(result.currency, tSettlement.currency);
      expect(result.createdAt, tSettlement.createdAt);
    });
  });

  group('fromJson', () {
    test('should return a valid model from JSON', () {
      final Map<String, dynamic> jsonMap = {
        'id': '1',
        'groupId': 'group1',
        'fromUserId': 'user1',
        'toUserId': 'user2',
        'amount': 100.0,
        'currency': 'USD',
        'createdAt': '2023-10-01T00:00:00.000',
      };
      final result = SettlementModel.fromJson(jsonMap);
      expect(result.toEntity(), equals(tSettlement));
    });
  });

  group('toJson', () {
    test('should return a JSON map containing the proper data', () {
      final result = tSettlementModel.toJson();
      final expectedMap = {
        'id': '1',
        'groupId': 'group1',
        'fromUserId': 'user1',
        'toUserId': 'user2',
        'amount': 100.0,
        'currency': 'USD',
        'createdAt': '2023-10-01T00:00:00.000',
      };
      expect(result, equals(expectedMap));
    });
  });
}
