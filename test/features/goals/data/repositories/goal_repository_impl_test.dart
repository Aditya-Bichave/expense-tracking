import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalLocalDataSource extends Mock implements GoalLocalDataSource {}

class MockGoalContributionLocalDataSource extends Mock
    implements GoalContributionLocalDataSource {}

void main() {
  late GoalRepositoryImpl repository;
  late MockGoalLocalDataSource mockLocalDataSource;
  late MockGoalContributionLocalDataSource mockContributionDataSource;

  setUp(() {
    mockLocalDataSource = MockGoalLocalDataSource();
    mockContributionDataSource = MockGoalContributionLocalDataSource();
    repository = GoalRepositoryImpl(
      localDataSource: mockLocalDataSource,
      contributionDataSource: mockContributionDataSource,
    );
    registerFallbackValue(
      GoalModel(
        id: '1',
        name: 'test',
        targetAmount: 100,
        statusIndex: 0,
        totalSavedCache: 0,
        createdAt: DateTime.now(),
      ),
    );
  });

  final tGoal = Goal(
    id: '1',
    name: 'Vacation',
    targetAmount: 1000,
    status: GoalStatus.active,
    totalSaved: 0,
    createdAt: DateTime.now(), // Fixed: Non-null createdAt
  );

  final tGoalValid = tGoal.copyWith(createdAt: DateTime.now());

  group('addGoal', () {
    test('should save goal with active status and 0 saved', () async {
      when(
        () => mockLocalDataSource.saveGoal(any()),
      ).thenAnswer((_) async => null);

      final result = await repository.addGoal(tGoalValid);

      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.saveGoal(any())).called(1);
    });
  });

  group('getGoals', () {
    test('should return goals excluding archived by default', () async {
      final activeModel = GoalModel.fromEntity(tGoalValid);
      final archivedModel = GoalModel.fromEntity(
        tGoalValid.copyWith(id: '2', status: GoalStatus.archived),
      );

      when(
        () => mockLocalDataSource.getGoals(),
      ).thenAnswer((_) async => [activeModel, archivedModel]);

      final result = await repository.getGoals();

      expect(result.isRight(), true);
      result.fold((l) => null, (list) {
        expect(list.length, 1);
        expect(list.first.id, '1');
      });
    });

    test('should return all goals when includeArchived is true', () async {
      final activeModel = GoalModel.fromEntity(tGoalValid);
      final archivedModel = GoalModel.fromEntity(
        tGoalValid.copyWith(id: '2', status: GoalStatus.archived),
      );

      when(
        () => mockLocalDataSource.getGoals(),
      ).thenAnswer((_) async => [activeModel, archivedModel]);

      final result = await repository.getGoals(includeArchived: true);

      expect(result.isRight(), true);
      result.fold((l) => null, (list) => expect(list.length, 2));
    });
  });
}
