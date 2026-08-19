import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/hive_adapter_harness.dart';

/// A settlement records that one member paid another back, so a dropped field
/// here means a debt that reappears or points at the wrong person. Both the
/// Hive adapter (typeId 16) and the JSON codec are checked field by field.
void main() {
  final adapter = SettlementModelAdapter();

  SettlementModel settlement() => SettlementModel(
    id: 's1',
    groupId: 'g1',
    fromUserId: 'u-payer',
    toUserId: 'u-payee',
    amount: 25.75,
    currency: 'GBP',
    createdAt: DateTime(2024, 4, 2, 9, 15),
  );

  void expectSameFields(SettlementModel actual, SettlementModel expected) {
    expect(actual.id, expected.id);
    expect(actual.groupId, expected.groupId);
    expect(actual.fromUserId, expected.fromUserId);
    expect(actual.toUserId, expected.toUserId);
    expect(actual.amount, expected.amount);
    expect(actual.currency, expected.currency);
    expect(actual.createdAt, expected.createdAt);
  }

  group('Hive adapter', () {
    test('keeps typeId 16', () {
      expect(adapter.typeId, 16);
    });

    test('survives a round trip', () {
      expectSameFields(roundTrip(adapter, settlement()), settlement());
    });

    test('every declared field is actually written', () {
      final declared = declaredFieldCount(adapter, settlement());
      final indices = writtenFieldIndices(adapter, settlement());

      expect(indices, hasLength(declared));
      expect(indices.toSet(), hasLength(indices.length));
      expect(indices, containsAll(List.generate(declared, (i) => i)));
    });

    test('the payer and payee do not swap', () {
      // Directional: reversing these turns a repayment into a new debt.
      final restored = roundTrip(adapter, settlement());

      expect(restored.fromUserId, 'u-payer');
      expect(restored.toUserId, 'u-payee');
    });

    test('adapters compare by type and id', () {
      expect(adapter, equals(SettlementModelAdapter()));
      expect(adapter.hashCode, SettlementModelAdapter().hashCode);
    });
  });

  group('JSON', () {
    test('survives a round trip', () {
      expectSameFields(
        SettlementModel.fromJson(settlement().toJson()),
        settlement(),
      );
    });

    test('an integer amount is read as a double', () {
      final restored = SettlementModel.fromJson({
        ...settlement().toJson(),
        'amount': 30,
      });

      expect(restored.amount, 30.0);
    });

    test('the timestamp survives as an exact instant', () {
      final restored = SettlementModel.fromJson(settlement().toJson());

      expect(restored.createdAt, DateTime(2024, 4, 2, 9, 15));
    });
  });
}
