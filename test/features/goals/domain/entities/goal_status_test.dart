import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';

void main() {
  group('GoalStatus', () {
    test('displayName should return correct string', () {
      expect(GoalStatus.active.displayName, 'Active');
      expect(GoalStatus.achieved.displayName, 'Achieved');
      expect(GoalStatus.archived.displayName, 'Archived');
    });
  });
}
