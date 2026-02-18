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

class FakeGoalModel extends Fake implements GoalModel {}

void main() {
  late GoalRepositoryImpl repository;
  late MockGoalLocalDataSource mockGoalDataSource;
  late MockGoalContributionLocalDataSource mockContributionDataSource;

  setUpAll(() {
    registerFallbackValue(FakeGoalModel());
  });

  setUp(() {
    mockGoalDataSource = MockGoalLocalDataSource();
    mockContributionDataSource = MockGoalContributionLocalDataSource();
    repository = GoalRepositoryImpl(
      localDataSource: mockGoalDataSource,
      contributionDataSource: mockContributionDataSource,
    );
  });

  final tGoal = Goal(
    id: '1',
    name: 'Car',
    targetAmount: 5000.0,
    totalSaved: 1000.0,
    targetDate: DateTime(2025, 1, 1),
    iconName: 'car',
    description: 'Save for car',
    status: GoalStatus.active,
    createdAt: DateTime.now(),
    achievedAt: null,
  );

  final tGoalModel = GoalModel(
    id: '1',
    name: 'Car',
    targetAmount: 5000.0,
    totalSavedCache: 1000.0,
    targetDate: DateTime(2025, 1, 1),
    iconName: 'car',
    description: 'Save for car',
    statusIndex: 0,
    createdAt: DateTime.now(),
    achievedAt: null,
  );

  group('getGoals', () {
    test('should return list of goals from data source', () async {
      // Arrange
      when(
        () => mockGoalDataSource.getGoals(),
      ).thenAnswer((_) async => [tGoalModel]);

      // Act
      final result = await repository.getGoals();

      // Assert
      expect(result.isRight(), isTrue);
      final goals = result.getOrElse(() => []);
      expect(goals.first.id, tGoal.id);
    });

    test('should return CacheFailure when data source fails', () async {
      // Arrange
      when(
        () => mockGoalDataSource.getGoals(),
      ).thenThrow(const CacheFailure('Hive Error'));

      // Act
      final result = await repository.getGoals();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (r) => fail('Should return failure'),
      );
    });
  });

  group('addGoal', () {
    test('should return added goal when successful', () async {
      // Arrange
      when(
        () => mockGoalDataSource.saveGoal(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.addGoal(tGoal);

      // Assert
      verify(() => mockGoalDataSource.saveGoal(any())).called(1);
      expect(result.isRight(), isTrue);
    });
  });

  group('deleteGoal', () {
    test('should delete goal and contributions', () async {
      // Arrange
      when(
        () => mockGoalDataSource.deleteGoal(any()),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockContributionDataSource.getContributionsForGoal(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockContributionDataSource.deleteContributions(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.deleteGoal('1');

      // Assert
      verify(() => mockGoalDataSource.deleteGoal('1')).called(1);
      verify(
        () => mockContributionDataSource.getContributionsForGoal('1'),
      ).called(1);
      verify(
        () => mockContributionDataSource.deleteContributions(any()),
      ).called(1);
      expect(result, const Right(null));
    });
  });

  group('updateGoal', () {
    test('should update goal', () async {
      // Arrange
      when(
        () => mockGoalDataSource.getGoalById(any()),
      ).thenAnswer((_) async => tGoalModel);
      when(
        () => mockGoalDataSource.saveGoal(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.updateGoal(tGoal);

      // Assert
      verify(() => mockGoalDataSource.saveGoal(any())).called(1);
      expect(result.isRight(), isTrue);
    });
  });
}
