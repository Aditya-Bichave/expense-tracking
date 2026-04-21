import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:expense_tracker/features/settlements/domain/entities/settlement.dart';

void main() {
  final tDate = DateTime(2023, 1, 1).toUtc();

  final tSettlementModel = SettlementModel(
    id: '1',
    groupId: 'group1',
    fromUserId: 'user1',
    toUserId: 'user2',
    amount: 100.5,
    currency: 'USD',
    createdAt: tDate,
  );

  final tSettlement = Settlement(
    id: '1',
    groupId: 'group1',
    fromUserId: 'user1',
    toUserId: 'user2',
    amount: 100.5,
    currency: 'USD',
    createdAt: tDate,
  );

  final tJson = {
    'id': '1',
    'groupId': 'group1',
    'fromUserId': 'user1',
    'toUserId': 'user2',
    'amount': 100.5,
    'currency': 'USD',
    'createdAt': tDate.toIso8601String(),
  };

  group('SettlementModel', () {
    test('should be a subclass of Settlement entity when converted', () {
      final result = tSettlementModel.toEntity();
      expect(result, isA<Settlement>());
      expect(result, equals(tSettlement));
    });

    test('should create a SettlementModel from a Settlement entity', () {
      final result = SettlementModel.fromEntity(tSettlement);
      expect(result.id, tSettlementModel.id);
      expect(result.groupId, tSettlementModel.groupId);
      expect(result.fromUserId, tSettlementModel.fromUserId);
      expect(result.toUserId, tSettlementModel.toUserId);
      expect(result.amount, tSettlementModel.amount);
      expect(result.currency, tSettlementModel.currency);
      expect(result.createdAt, tSettlementModel.createdAt);
    });

    test('should create a SettlementModel from JSON', () {
      final result = SettlementModel.fromJson(tJson);
      expect(result.id, tSettlementModel.id);
      expect(result.groupId, tSettlementModel.groupId);
      expect(result.fromUserId, tSettlementModel.fromUserId);
      expect(result.toUserId, tSettlementModel.toUserId);
      expect(result.amount, tSettlementModel.amount);
      expect(result.currency, tSettlementModel.currency);
      expect(result.createdAt, tSettlementModel.createdAt);
    });

    test('should convert a SettlementModel to JSON', () {
      final result = tSettlementModel.toJson();
      expect(result, tJson);
    });
  });
}
