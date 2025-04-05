// lib/features/goals/domain/entities/goal_status.dart
enum GoalStatus { active, achieved, archived }

extension GoalStatusExtension on GoalStatus {
  String get displayName {
    switch (this) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.achieved:
        return 'Achieved';
      case GoalStatus.archived:
        return 'Archived';
    }
  }
}
