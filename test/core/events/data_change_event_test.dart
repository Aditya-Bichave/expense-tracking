import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';

void main() {
  group('DataChangeReason enum', () {
    test('has all expected values', () {
      expect(DataChangeReason.values.length, 4);
      expect(DataChangeReason.values, contains(DataChangeReason.added));
      expect(DataChangeReason.values, contains(DataChangeReason.updated));
      expect(DataChangeReason.values, contains(DataChangeReason.deleted));
      expect(DataChangeReason.values, contains(DataChangeReason.reset));
    });

    test('can be accessed by name', () {
      expect(DataChangeReason.values.byName('added'), DataChangeReason.added);
      expect(
        DataChangeReason.values.byName('updated'),
        DataChangeReason.updated,
      );
      expect(
        DataChangeReason.values.byName('deleted'),
        DataChangeReason.deleted,
      );
      expect(DataChangeReason.values.byName('reset'), DataChangeReason.reset);
    });
  });

  group('DataChangeType enum', () {
    test('has all expected values', () {
      expect(DataChangeType.values.length, 9);
      expect(DataChangeType.values, contains(DataChangeType.account));
      expect(DataChangeType.values, contains(DataChangeType.income));
      expect(DataChangeType.values, contains(DataChangeType.expense));
      expect(DataChangeType.values, contains(DataChangeType.settings));
      expect(DataChangeType.values, contains(DataChangeType.category));
      expect(DataChangeType.values, contains(DataChangeType.goal));
      expect(
        DataChangeType.values,
        contains(DataChangeType.goalContribution),
      );
      expect(DataChangeType.values, contains(DataChangeType.budget));
      expect(DataChangeType.values, contains(DataChangeType.recurringRule));
      expect(DataChangeType.values, contains(DataChangeType.system));
    });

    test('can be accessed by name', () {
      expect(
        DataChangeType.values.byName('account'),
        DataChangeType.account,
      );
      expect(DataChangeType.values.byName('expense'), DataChangeType.expense);
      expect(DataChangeType.values.byName('system'), DataChangeType.system);
    });
  });

  group('DataChangedEvent', () {
    test('can be created with type and reason', () {
      const event = DataChangedEvent(
        type: DataChangeType.expense,
        reason: DataChangeReason.added,
      );
      expect(event.type, DataChangeType.expense);
      expect(event.reason, DataChangeReason.added);
    });

    test('properties match constructor parameters', () {
      const event1 = DataChangedEvent(
        type: DataChangeType.expense,
        reason: DataChangeReason.added,
      );
      const event2 = DataChangedEvent(
        type: DataChangeType.expense,
        reason: DataChangeReason.added,
      );
      expect(event1.type, event2.type);
      expect(event1.reason, event2.reason);
    });

    test('different events have different properties', () {
      const event1 = DataChangedEvent(
        type: DataChangeType.expense,
        reason: DataChangeReason.added,
      );
      const event2 = DataChangedEvent(
        type: DataChangeType.income,
        reason: DataChangeReason.updated,
      );
      expect(event1.type, isNot(event2.type));
      expect(event1.reason, isNot(event2.reason));
    });

    test('toString contains type and reason', () {
      const event = DataChangedEvent(
        type: DataChangeType.account,
        reason: DataChangeReason.deleted,
      );
      final str = event.toString();
      expect(str, contains('DataChangedEvent'));
      expect(str, contains('account'));
      expect(str, contains('deleted'));
    });

    test('works with all DataChangeType values', () {
      for (final type in DataChangeType.values) {
        const event = DataChangedEvent(
          type: DataChangeType.account,
          reason: DataChangeReason.added,
        );
        expect(event, isNotNull);
      }
    });

    test('works with all DataChangeReason values', () {
      for (final reason in DataChangeReason.values) {
        const event = DataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.added,
        );
        expect(event, isNotNull);
      }
    });

    test('system reset event can be created', () {
      const event = DataChangedEvent(
        type: DataChangeType.system,
        reason: DataChangeReason.reset,
      );
      expect(event.type, DataChangeType.system);
      expect(event.reason, DataChangeReason.reset);
    });
  });
}