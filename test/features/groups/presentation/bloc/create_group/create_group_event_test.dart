import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';

void main() {
  group('CreateGroupEvent', () {
    test('CreateGroupSubmitted props should be correct', () {
      const event = CreateGroupSubmitted(
        name: 'Test',
        type: GroupType.trip,
        currency: 'USD',
        userId: 'u1',
      );

      expect(event.isEdit, isFalse);
      expect(event.props, [
        'Test',
        GroupType.trip,
        'USD',
        'u1',
        null,
        null,
        null,
        null,
        false,
        null,
      ]);
    });

    test('CreateGroupSubmitted equality should work', () {
      const event1 = CreateGroupSubmitted(
        name: 'Test',
        type: GroupType.trip,
        currency: 'USD',
        userId: 'u1',
      );

      const event2 = CreateGroupSubmitted(
        name: 'Test',
        type: GroupType.trip,
        currency: 'USD',
        userId: 'u1',
      );

      const event3 = CreateGroupSubmitted(
        name: 'Test2',
        type: GroupType.trip,
        currency: 'USD',
        userId: 'u1',
      );

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('CreateGroupSubmitted reports edit mode when groupId is provided', () {
      const event = CreateGroupSubmitted(
        name: 'Test',
        type: GroupType.trip,
        currency: 'USD',
        userId: 'u1',
        groupId: 'g1',
      );

      expect(event.isEdit, isTrue);
    });
  });
}
