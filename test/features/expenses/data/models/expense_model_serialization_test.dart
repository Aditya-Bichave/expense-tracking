import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/hive_adapter_harness.dart';

/// ExpenseModel is persisted two ways — through the Hive adapter (typeId 0) and
/// as JSON inside backup files. Both codecs are generated, so the risk is not
/// that a line is wrong but that a *field is silently dropped*: a new
/// `HiveField` that nobody writes, or a JSON key that round-trips to null.
/// These tests assert every field survives a full round trip.
void main() {
  final adapter = ExpenseModelAdapter();

  ExpenseModel full() => ExpenseModel(
    id: 'e1',
    title: 'Dinner',
    amount: 42.5,
    date: DateTime(2024, 3, 15, 19, 30),
    categoryId: 'cat-food',
    categorizationStatusValue: 'categorized',
    accountId: 'acc-1',
    confidenceScoreValue: 0.87,
    isRecurring: true,
    merchantId: 'merchant-9',
    groupId: 'grp-2',
    createdBy: 'user-7',
    currency: 'EUR',
    notes: 'split with Sam',
    receiptUrl: 'https://example.test/r.jpg',
    clientGeneratedId: 'client-abc',
  );

  // Only the required fields; everything else falls to its default.
  ExpenseModel minimal() => ExpenseModel(
    id: 'e2',
    title: 'Coffee',
    amount: 3,
    date: DateTime(2024, 1, 2),
    accountId: 'acc-1',
  );

  void expectSameFields(ExpenseModel actual, ExpenseModel expected) {
    expect(actual.id, expected.id);
    expect(actual.title, expected.title);
    expect(actual.amount, expected.amount);
    expect(actual.date, expected.date);
    expect(actual.categoryId, expected.categoryId);
    expect(
      actual.categorizationStatusValue,
      expected.categorizationStatusValue,
    );
    expect(actual.accountId, expected.accountId);
    expect(actual.confidenceScoreValue, expected.confidenceScoreValue);
    expect(actual.isRecurring, expected.isRecurring);
    expect(actual.merchantId, expected.merchantId);
    expect(actual.groupId, expected.groupId);
    expect(actual.createdBy, expected.createdBy);
    expect(actual.currency, expected.currency);
    expect(actual.notes, expected.notes);
    expect(actual.receiptUrl, expected.receiptUrl);
    expect(actual.clientGeneratedId, expected.clientGeneratedId);
  }

  group('Hive adapter', () {
    test('keeps typeId 0', () {
      // Changing this silently orphans every stored expense.
      expect(adapter.typeId, 0);
    });

    test('a fully populated model survives a round trip', () {
      expectSameFields(roundTrip(adapter, full()), full());
    });

    test('a minimal model round-trips with its defaults intact', () {
      final restored = roundTrip(adapter, minimal());

      expect(restored.categorizationStatusValue, 'uncategorized');
      expect(restored.currency, 'USD');
      expect(restored.isRecurring, isFalse);
      expect(restored.categoryId, isNull);
      expect(restored.confidenceScoreValue, isNull);
    });

    test('every declared field is actually written', () {
      // Guards the common generator drift: a field added to the model but
      // never emitted by write(), which reads back as null forever.
      final indices = writtenFieldIndices(adapter, full());

      expect(indices, hasLength(declaredFieldCount(adapter, full())));
      expect(indices.toSet(), hasLength(indices.length));
      expect(indices, containsAll(List.generate(16, (i) => i)));
    });

    test('adapters compare by type and id', () {
      expect(adapter, equals(ExpenseModelAdapter()));
      expect(adapter.hashCode, ExpenseModelAdapter().hashCode);
    });
  });

  group('JSON', () {
    test('a fully populated model survives a round trip', () {
      final restored = ExpenseModel.fromJson(full().toJson());

      expectSameFields(restored, full());
    });

    test('a minimal model round-trips with its defaults intact', () {
      final restored = ExpenseModel.fromJson(minimal().toJson());

      expect(restored.categorizationStatusValue, 'uncategorized');
      expect(restored.currency, 'USD');
      expect(restored.isRecurring, isFalse);
    });

    test('absent optional keys fall back to their defaults', () {
      // A backup written by an older build will not carry these keys at all.
      final restored = ExpenseModel.fromJson({
        'id': 'e3',
        'title': 'Legacy',
        'amount': 9.5,
        'date': DateTime(2023, 5, 1).toIso8601String(),
        'accountId': 'acc-1',
      });

      expect(restored.categorizationStatusValue, 'uncategorized');
      expect(restored.currency, 'USD');
      expect(restored.isRecurring, isFalse);
      expect(restored.notes, isNull);
      expect(restored.receiptUrl, isNull);
    });

    test('an integer amount is read as a double', () {
      // JSON has no int/double distinction; 42 must not blow up on cast.
      final restored = ExpenseModel.fromJson({
        'id': 'e4',
        'title': 'Round number',
        'amount': 42,
        'date': DateTime(2023, 5, 1).toIso8601String(),
        'accountId': 'acc-1',
        'confidenceScoreValue': 1,
      });

      expect(restored.amount, 42.0);
      expect(restored.confidenceScoreValue, 1.0);
    });

    test('the date survives as an exact instant', () {
      final restored = ExpenseModel.fromJson(full().toJson());

      expect(restored.date, DateTime(2024, 3, 15, 19, 30));
    });
  });
}
