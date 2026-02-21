import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<GoalContributionModel> {}

void main() {
  late HiveContributionLocalDataSource dataSource;
  late MockBox mockBox;

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveContributionLocalDataSource(mockBox);
  });

  final tDate = DateTime(2023, 5, 10);
  final tGoalId = 'goal_1';
  final tContribution1 = GoalContributionModel(
    id: '1',
    goalId: tGoalId,
    amount: 100,
    date: tDate,
    createdAt: tDate,
  );
  final tContribution2 = GoalContributionModel(
    id: '2',
    goalId: tGoalId,
    amount: 50,
    date: tDate.add(const Duration(days: 5)), // May 15
    createdAt: tDate,
  );
  final tContribution3 = GoalContributionModel(
    id: '3',
    goalId: tGoalId,
    amount: 75,
    date: tDate.subtract(const Duration(days: 5)), // May 5
    createdAt: tDate,
  );
  final tContributionOtherGoal = GoalContributionModel(
    id: '4',
    goalId: 'goal_2',
    amount: 200,
    date: tDate,
    createdAt: tDate,
  );

  final allContributions = [
    tContribution1,
    tContribution2,
    tContribution3,
    tContributionOtherGoal,
  ];

  group('getContributionsForGoal', () {
    test('should return all contributions for a goal when no dates provided', () async {
      // Arrange
      when(() => mockBox.values).thenReturn(allContributions);

      // Act
      final result = await dataSource.getContributionsForGoal(tGoalId);

      // Assert
      expect(result.length, 3);
      expect(result, containsAll([tContribution1, tContribution2, tContribution3]));
    });

    test('should filter by startDate', () async {
      // Arrange
      when(() => mockBox.values).thenReturn(allContributions);
      final startDate = DateTime(2023, 5, 10); // Should include tContribution1 (May 10) and tContribution2 (May 15)

      // Act
      final result = await dataSource.getContributionsForGoal(tGoalId, startDate: startDate);

      // Assert
      expect(result.length, 2);
      expect(result, containsAll([tContribution1, tContribution2]));
      expect(result, isNot(contains(tContribution3))); // May 5 is before May 10
    });

    test('should filter by endDate', () async {
      // Arrange
      when(() => mockBox.values).thenReturn(allContributions);
      final endDate = DateTime(2023, 5, 10); // Should include tContribution1 (May 10) and tContribution3 (May 5)

      // Act
      final result = await dataSource.getContributionsForGoal(tGoalId, endDate: endDate);

      // Assert
      expect(result.length, 2);
      expect(result, containsAll([tContribution1, tContribution3]));
      expect(result, isNot(contains(tContribution2))); // May 15 is after May 10
    });

    test('should filter by start and end date', () async {
      // Arrange
      when(() => mockBox.values).thenReturn(allContributions);
      final startDate = DateTime(2023, 5, 6);
      final endDate = DateTime(2023, 5, 14);
      // tContribution3 (May 5) -> Excluded (before May 6)
      // tContribution1 (May 10) -> Included
      // tContribution2 (May 15) -> Excluded (after May 14)

      // Act
      final result = await dataSource.getContributionsForGoal(
        tGoalId,
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(result.length, 1);
      expect(result.first, tContribution1);
    });
  });
}
