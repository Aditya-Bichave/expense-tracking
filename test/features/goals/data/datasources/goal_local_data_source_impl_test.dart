import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/core/error/failure.dart';

class MockBox extends Mock implements Box<GoalModel> {}

class FakeGoalModel extends Fake implements GoalModel {}

void main() {
  late HiveGoalLocalDataSource dataSource;
  late MockBox mockBox;

  final tGoal = GoalModel(
    id: '1',
    name: 'Test Goal',
    targetAmount: 1000,
    statusIndex: 0,
    totalSavedCache: 100,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(FakeGoalModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveGoalLocalDataSource(mockBox);
  });

  group('HiveGoalLocalDataSource', () {
    group('saveGoal', () {
      test('should save goal to box', () async {
        when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});

        await dataSource.saveGoal(tGoal);

        verify(() => mockBox.put(tGoal.id, tGoal)).called(1);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.put(any(), any()))
            .thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.saveGoal(tGoal),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('getGoals', () {
      test('should return list of goals from box', () async {
        final List<GoalModel> tGoals = [tGoal];
        when(() => mockBox.values).thenReturn(tGoals);

        final result = await dataSource.getGoals();

        expect(result, equals(tGoals));
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.values).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.getGoals(),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('getGoalById', () {
      test('should return goal if found', () async {
        when(() => mockBox.get(any())).thenReturn(tGoal);

        final result = await dataSource.getGoalById(tGoal.id);

        expect(result, equals(tGoal));
        verify(() => mockBox.get(tGoal.id)).called(1);
      });

      test('should return null if not found', () async {
        when(() => mockBox.get(any())).thenReturn(null);

        final result = await dataSource.getGoalById('non-existent');

        expect(result, isNull);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.get(any())).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.getGoalById(tGoal.id),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('deleteGoal', () {
      test('should delete goal from box', () async {
        when(() => mockBox.delete(any())).thenAnswer((_) async => {});

        await dataSource.deleteGoal(tGoal.id);

        verify(() => mockBox.delete(tGoal.id)).called(1);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.delete(any())).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.deleteGoal(tGoal.id),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('clearAllGoals', () {
      test('should clear box', () async {
        when(() => mockBox.clear()).thenAnswer((_) async => 0);

        await dataSource.clearAllGoals();

        verify(() => mockBox.clear()).called(1);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.clear()).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.clearAllGoals(),
          throwsA(isA<CacheFailure>()),
        );
      });
    });
  });
}
