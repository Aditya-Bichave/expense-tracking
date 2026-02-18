import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<GoalModel> {}

class FakeGoalModel extends Fake implements GoalModel {}

void main() {
  late HiveGoalLocalDataSource dataSource;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeGoalModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveGoalLocalDataSource(mockBox);
  });

  final tGoalModel = GoalModel(
    id: '1',
    name: 'Car',
    targetAmount: 5000.0,
    totalSavedCache: 1000.0,
    targetDate: DateTime(2025, 1, 1),
    iconName: 'car',
    description: 'Save for car',
    statusIndex: 0, // active
    createdAt: DateTime.now(),
    achievedAt: null,
  );

  group('getGoals', () {
    test('should return list of GoalModel from Hive', () async {
      // Arrange
      when(() => mockBox.values).thenReturn([tGoalModel]);

      // Act
      final result = await dataSource.getGoals();

      // Assert
      expect(result, [tGoalModel]);
    });

    test('should throw CacheFailure when Hive access fails', () async {
      // Arrange
      when(() => mockBox.values).thenThrow(Exception());

      // Act & Assert
      expect(() => dataSource.getGoals(), throwsA(isA<CacheFailure>()));
    });
  });

  group('saveGoal', () {
    test('should add/update goal to Hive', () async {
      // Arrange
      when(
        () => mockBox.put(any(), any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.saveGoal(tGoalModel);

      // Assert
      verify(() => mockBox.put(tGoalModel.id, tGoalModel)).called(1);
    });

    test('should throw CacheFailure when saving fails', () async {
      // Arrange
      when(() => mockBox.put(any(), any())).thenThrow(Exception());

      // Act & Assert
      expect(
        () => dataSource.saveGoal(tGoalModel),
        throwsA(isA<CacheFailure>()),
      );
    });
  });

  group('deleteGoal', () {
    test('should delete goal from Hive', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.deleteGoal('1');

      // Assert
      verify(() => mockBox.delete('1')).called(1);
    });

    test('should throw CacheFailure when deletion fails', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenThrow(Exception());

      // Act & Assert
      expect(() => dataSource.deleteGoal('1'), throwsA(isA<CacheFailure>()));
    });
  });
}
