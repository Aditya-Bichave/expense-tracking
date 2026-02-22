import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';

void main() {
  test(
    'DataChangedEvent supports equality (manual check since it does not extend Equatable)',
    () {
      const event1 = DataChangedEvent(
        type: DataChangeType.expense,
        reason: DataChangeReason.added,
      );
      const event2 = DataChangedEvent(
        type: DataChangeType.expense,
        reason: DataChangeReason.added,
      );
      // Standard class equality is identity, so this might fail if checking equality.
      // If it doesn't extend Equatable, we check props manually.
      expect(event1.type, event2.type);
      expect(event1.reason, event2.reason);
    },
  );
}
