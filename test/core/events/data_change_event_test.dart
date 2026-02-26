import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataChangedEvent', () {
    test(
      'supports equality (manual check since it does not extend Equatable)',
      () {
        // It doesn't extend Equatable, so default equality is identity.
        // But we can check values.
        const event1 = DataChangedEvent(
          type: DataChangeType.account,
          reason: DataChangeReason.added,
        );

        expect(event1.type, DataChangeType.account);
        expect(event1.reason, DataChangeReason.added);
        expect(event1.toString(), contains('DataChangeType.account'));
      },
    );
  });
}
