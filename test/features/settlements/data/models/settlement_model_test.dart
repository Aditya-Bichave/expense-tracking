import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:expense_tracker/features/settlements/domain/entities/settlement.dart';

void main() {
  group('SettlementModel Test', () {
    final tCreatedAt = DateTime(2023, 1, 1, 12, 0);

    final tModel = SettlementModel(
      id: '1',
      groupId: 'g1',
      fromUserId: 'u1',
      toUserId: 'u2',
      amount: 100.0,
      currency: 'USD',
      createdAt: tCreatedAt,
    );

    final tEntity = Settlement(
      id: '1',
      groupId: 'g1',
      fromUserId: 'u1',
      toUserId: 'u2',
      amount: 100.0,
      currency: 'USD',
      createdAt: tCreatedAt,
    );

    test('should return a valid model from entity', () {
      final result = SettlementModel.fromEntity(tEntity);

      expect(result.id, tModel.id);
      expect(result.groupId, tModel.groupId);
      expect(result.fromUserId, tModel.fromUserId);
      expect(result.toUserId, tModel.toUserId);
      expect(result.amount, tModel.amount);
      expect(result.currency, tModel.currency);
      expect(result.createdAt, tModel.createdAt);
    });

    test('should return a valid entity from model', () {
      final result = tModel.toEntity();

      expect(result.id, tEntity.id);
      expect(result.groupId, tEntity.groupId);
      expect(result.fromUserId, tEntity.fromUserId);
      expect(result.toUserId, tEntity.toUserId);
      expect(result.amount, tEntity.amount);
      expect(result.currency, tEntity.currency);
      expect(result.createdAt, tEntity.createdAt);
    });

    test('should return a valid JSON map', () {
      final json = tModel.toJson();
      expect(json, {
        'id': '1',
        'groupId': 'g1',
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'amount': 100.0,
        'currency': 'USD',
        'createdAt': tCreatedAt.toIso8601String(),
      });
    });

    test('should return a valid model from JSON map', () {
      final json = {
        'id': '1',
        'groupId': 'g1',
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'amount': 100.0,
        'currency': 'USD',
        'createdAt': tCreatedAt.toIso8601String(),
      };

      final result = SettlementModel.fromJson(json);

      expect(result.id, tModel.id);
      expect(result.groupId, tModel.groupId);
      expect(result.fromUserId, tModel.fromUserId);
      expect(result.toUserId, tModel.toUserId);
      expect(result.amount, tModel.amount);
      expect(result.currency, tModel.currency);
      expect(result.createdAt, tModel.createdAt);
    });
  });
}
