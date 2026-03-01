import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';

void main() {
  group('CreateGroupState', () {
    test('CreateGroupInitial props should be empty', () {
      expect(CreateGroupInitial().props, []);
    });

    test('CreateGroupLoading props should be empty', () {
      expect(CreateGroupLoading().props, []);
    });

    test('CreateGroupSuccess props should contain group', () {
      final dateTime = DateTime.parse('2023-01-01T00:00:00.000Z');
      final groupEntity = GroupEntity(
        id: 'g1',
        name: 'Test',
        type: GroupType.trip,
        currency: 'USD',
        createdBy: 'u1',
        createdAt: dateTime,
        updatedAt: dateTime,
      );
      final state = CreateGroupSuccess(groupEntity);

      expect(state.props, [groupEntity]);
    });

    test('CreateGroupFailure props should contain message', () {
      const state = CreateGroupFailure('error message');

      expect(state.props, ['error message']);
    });
  });
}
