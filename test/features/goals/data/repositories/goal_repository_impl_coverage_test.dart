import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/either_matchers.dart';

class MockGoalLocalDataSource extends Mock implements GoalLocalDataSource {}

class MockGoalContributionLocalDataSource extends Mock
    implements GoalContributionLocalDataSource {}

class _FakeGoalModel extends Fake implements GoalModel {}

void main() {
  late MockGoalLocalDataSource dataSource;
  late MockGoalContributionLocalDataSource contributionDataSource;
  late GoalRepositoryImpl repository;

  final createdAt = DateTime(2024, 1, 1);
  final achievedAt = DateTime(2024, 5, 1);

  GoalModel model({
    String id = 'g1',
    String name = 'Laptop',
    double target = 1000,
    double saved = 0,
    GoalStatus status = GoalStatus.active,
    DateTime? achieved,
    DateTime? createdOn,
  }) => GoalModel(
    id: id,
    name: name,
    targetAmount: target,
    statusIndex: status.index,
    totalSavedCache: saved,
    createdAt: createdOn ?? createdAt,
    achievedAt: achieved,
    iconName: 'savings',
  );

  Goal entity({
    String id = 'g1',
    String name = 'Laptop',
    double target = 1000,
    GoalStatus status = GoalStatus.active,
    double saved = 0,
  }) => Goal(
    id: id,
    name: name,
    targetAmount: target,
    status: status,
    totalSaved: saved,
    createdAt: createdAt,
    iconName: 'savings',
  );

  GoalContributionModel contribution(String id) => GoalContributionModel(
    id: id,
    goalId: 'g1',
    amount: 10,
    date: createdAt,
    createdAt: createdAt,
  );

  setUpAll(() {
    registerFallbackValue(_FakeGoalModel());
  });

  setUp(() {
    dataSource = MockGoalLocalDataSource();
    contributionDataSource = MockGoalContributionLocalDataSource();
    repository = GoalRepositoryImpl(
      localDataSource: dataSource,
      contributionDataSource: contributionDataSource,
    );
  });

  group('addGoal', () {
    test('always saves a new goal as active with zero saved', () async {
      when(() => dataSource.saveGoal(any())).thenAnswer((_) async {});

      // Even if the caller hands over a goal that claims progress, a new goal
      // must start from zero — contributions own that number.
      final result = await repository.addGoal(
        entity(saved: 500, status: GoalStatus.achieved),
      );

      final saved =
          verify(() => dataSource.saveGoal(captureAny())).captured.single
              as GoalModel;
      expect(saved.totalSavedCache, 0.0);
      expect(saved.statusIndex, GoalStatus.active.index);
      expect(rightOf(result).name, 'Laptop');
    });

    test('maps a data source error to CacheFailure', () async {
      when(() => dataSource.saveGoal(any())).thenThrow(Exception('disk'));

      expect(
        leftOf(await repository.addGoal(entity())),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          contains('Failed to add goal'),
        ),
      );
    });
  });

  group('archiveGoal', () {
    test('flips the status to archived and keeps the saved cache', () async {
      when(
        () => dataSource.getGoalById('g1'),
      ).thenAnswer((_) async => model(saved: 250, achieved: achievedAt));
      when(() => dataSource.saveGoal(any())).thenAnswer((_) async {});

      final result = await repository.archiveGoal('g1');

      final saved =
          verify(() => dataSource.saveGoal(captureAny())).captured.single
              as GoalModel;
      expect(saved.statusIndex, GoalStatus.archived.index);
      expect(saved.totalSavedCache, 250);
      expect(saved.achievedAt, achievedAt);
      expect(rightOf(result).status, GoalStatus.archived);
    });

    test('returns CacheFailure when the goal does not exist', () async {
      when(() => dataSource.getGoalById('ghost')).thenAnswer((_) async => null);

      expect(
        leftOf(await repository.archiveGoal('ghost')),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'Goal not found to archive.',
        ),
      );
      verifyNever(() => dataSource.saveGoal(any()));
    });

    test('maps a write error to CacheFailure', () async {
      when(() => dataSource.getGoalById('g1')).thenAnswer((_) async => model());
      when(() => dataSource.saveGoal(any())).thenThrow(Exception('locked'));

      expect(
        leftOf(await repository.archiveGoal('g1')).message,
        contains('Failed to archive goal'),
      );
    });
  });

  group('deleteGoal', () {
    test(
      'cascades to the goal contributions before deleting the goal',
      () async {
        when(
          () => contributionDataSource.getContributionsForGoal('g1'),
        ).thenAnswer((_) async => [contribution('c1'), contribution('c2')]);
        when(
          () => contributionDataSource.deleteContributions(any()),
        ).thenAnswer((_) async {});
        when(() => dataSource.deleteGoal('g1')).thenAnswer((_) async {});

        final result = await repository.deleteGoal('g1');

        expect(result.isRight(), isTrue);
        final ids =
            verify(
                  () =>
                      contributionDataSource.deleteContributions(captureAny()),
                ).captured.single
                as List<String>;
        expect(ids, ['c1', 'c2']);
        verify(() => dataSource.deleteGoal('g1')).called(1);
      },
    );

    test('a goal with no contributions still deletes cleanly', () async {
      when(
        () => contributionDataSource.getContributionsForGoal('g1'),
      ).thenAnswer((_) async => []);
      when(
        () => contributionDataSource.deleteContributions(any()),
      ).thenAnswer((_) async {});
      when(() => dataSource.deleteGoal('g1')).thenAnswer((_) async {});

      expect((await repository.deleteGoal('g1')).isRight(), isTrue);
    });

    test('a failure in the cascade aborts before deleting the goal', () async {
      when(
        () => contributionDataSource.getContributionsForGoal('g1'),
      ).thenThrow(Exception('contribution box closed'));

      expect(
        leftOf(await repository.deleteGoal('g1')).message,
        contains('Failed to delete goal'),
      );
      verifyNever(() => dataSource.deleteGoal(any()));
    });
  });

  group('getGoalById', () {
    test('returns the mapped entity when present', () async {
      when(
        () => dataSource.getGoalById('g1'),
      ).thenAnswer((_) async => model(name: 'Boat', saved: 100));

      final goal = rightOf(await repository.getGoalById('g1'));

      expect(goal?.name, 'Boat');
      expect(goal?.totalSaved, 100);
    });

    test('returns null when absent', () async {
      when(() => dataSource.getGoalById('ghost')).thenAnswer((_) async => null);

      expect(rightOf(await repository.getGoalById('ghost')), isNull);
    });

    test('maps a read error to CacheFailure', () async {
      when(() => dataSource.getGoalById('g1')).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.getGoalById('g1')).message,
        contains('Failed to get goal details'),
      );
    });
  });

  group('getGoals', () {
    test('hides archived goals by default', () async {
      when(() => dataSource.getGoals()).thenAnswer(
        (_) async => [
          model(id: 'g1', name: 'Active'),
          model(id: 'g2', name: 'Archived', status: GoalStatus.archived),
        ],
      );

      final goals = rightOf(await repository.getGoals());

      expect(goals.map((g) => g.name), ['Active']);
    });

    test('includes archived goals when asked', () async {
      when(() => dataSource.getGoals()).thenAnswer(
        (_) async => [
          model(id: 'g1', name: 'Active'),
          model(id: 'g2', name: 'Archived', status: GoalStatus.archived),
        ],
      );

      final goals = rightOf(await repository.getGoals(includeArchived: true));

      expect(goals, hasLength(2));
    });

    test('sorts by completion percentage, highest first', () async {
      when(() => dataSource.getGoals()).thenAnswer(
        (_) async => [
          model(id: 'g1', name: 'Quarter', target: 100, saved: 25),
          model(id: 'g2', name: 'ThreeQuarters', target: 100, saved: 75),
          model(id: 'g3', name: 'Half', target: 100, saved: 50),
        ],
      );

      final goals = rightOf(await repository.getGoals());

      expect(goals.map((g) => g.name), ['ThreeQuarters', 'Half', 'Quarter']);
    });

    test('breaks ties on completion by newest first', () async {
      when(() => dataSource.getGoals()).thenAnswer(
        (_) async => [
          model(
            id: 'g1',
            name: 'Older',
            target: 100,
            saved: 50,
            createdOn: DateTime(2024, 1, 1),
          ),
          model(
            id: 'g2',
            name: 'Newer',
            target: 100,
            saved: 50,
            createdOn: DateTime(2024, 6, 1),
          ),
        ],
      );

      final goals = rightOf(await repository.getGoals());

      expect(goals.map((g) => g.name), ['Newer', 'Older']);
    });

    test('returns an empty list when there are no goals', () async {
      when(() => dataSource.getGoals()).thenAnswer((_) async => []);

      expect(rightOf(await repository.getGoals()), isEmpty);
    });

    test('maps a read error to CacheFailure', () async {
      when(() => dataSource.getGoals()).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.getGoals()).message,
        contains('Failed to load goals'),
      );
    });
  });

  group('updateGoal', () {
    test('preserves the saved cache rather than trusting the caller', () async {
      when(
        () => dataSource.getGoalById('g1'),
      ).thenAnswer((_) async => model(saved: 300));
      when(() => dataSource.saveGoal(any())).thenAnswer((_) async {});

      final result = await repository.updateGoal(
        entity(name: 'Renamed', target: 2000, saved: 0),
      );

      final saved =
          verify(() => dataSource.saveGoal(captureAny())).captured.single
              as GoalModel;
      expect(saved.name, 'Renamed');
      expect(saved.targetAmount, 2000);
      // Contributions own totalSaved; an update must not reset it.
      expect(saved.totalSavedCache, 300);
      expect(rightOf(result).totalSaved, 300);
    });

    test(
      'marks the goal achieved once the saved cache clears the target',
      () async {
        when(
          () => dataSource.getGoalById('g1'),
        ).thenAnswer((_) async => model(saved: 1200));
        when(() => dataSource.saveGoal(any())).thenAnswer((_) async {});

        await repository.updateGoal(entity(target: 1000));

        final saved =
            verify(() => dataSource.saveGoal(captureAny())).captured.single
                as GoalModel;
        expect(saved.statusIndex, GoalStatus.achieved.index);
        expect(saved.achievedAt, isNotNull);
      },
    );

    test(
      'keeps the original achievement timestamp if already achieved',
      () async {
        when(
          () => dataSource.getGoalById('g1'),
        ).thenAnswer((_) async => model(saved: 1200, achieved: achievedAt));
        when(() => dataSource.saveGoal(any())).thenAnswer((_) async {});

        await repository.updateGoal(entity(target: 1000));

        final saved =
            verify(() => dataSource.saveGoal(captureAny())).captured.single
                as GoalModel;
        expect(saved.achievedAt, achievedAt);
      },
    );

    test(
      'raising the target un-achieves the goal and clears the timestamp',
      () async {
        when(
          () => dataSource.getGoalById('g1'),
        ).thenAnswer((_) async => model(saved: 500, achieved: achievedAt));
        when(() => dataSource.saveGoal(any())).thenAnswer((_) async {});

        await repository.updateGoal(entity(target: 5000));

        final saved =
            verify(() => dataSource.saveGoal(captureAny())).captured.single
                as GoalModel;
        expect(saved.statusIndex, GoalStatus.active.index);
        expect(saved.achievedAt, isNull);
      },
    );

    test('an archived goal below target stays archived', () async {
      when(
        () => dataSource.getGoalById('g1'),
      ).thenAnswer((_) async => model(saved: 100, status: GoalStatus.archived));
      when(() => dataSource.saveGoal(any())).thenAnswer((_) async {});

      await repository.updateGoal(
        entity(target: 1000, status: GoalStatus.archived),
      );

      final saved =
          verify(() => dataSource.saveGoal(captureAny())).captured.single
              as GoalModel;
      expect(saved.statusIndex, GoalStatus.archived.index);
    });

    test('returns CacheFailure when the goal is missing', () async {
      when(() => dataSource.getGoalById('g1')).thenAnswer((_) async => null);

      expect(
        leftOf(await repository.updateGoal(entity())).message,
        contains('not found for update'),
      );
      verifyNever(() => dataSource.saveGoal(any()));
    });

    test('maps a write error to CacheFailure', () async {
      when(() => dataSource.getGoalById('g1')).thenAnswer((_) async => model());
      when(() => dataSource.saveGoal(any())).thenThrow(Exception('locked'));

      expect(
        leftOf(await repository.updateGoal(entity())).message,
        contains('Failed to update goal'),
      );
    });
  });
}
