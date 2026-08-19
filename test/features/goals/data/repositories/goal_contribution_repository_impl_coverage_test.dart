import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_contribution_repository_impl.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/either_matchers.dart';

class MockContributionDataSource extends Mock
    implements GoalContributionLocalDataSource {}

class MockGoalDataSource extends Mock implements GoalLocalDataSource {}

class _FakeContributionModel extends Fake implements GoalContributionModel {}

class _FakeGoalModel extends Fake implements GoalModel {}

/// The contribution repository owns the `totalSavedCache` on the goal: every
/// write recomputes it from the contributions. These tests pin that
/// recalculation, because a stale cache is what makes a goal show the wrong
/// progress or never reach "achieved".
void main() {
  late MockContributionDataSource contributions;
  late MockGoalDataSource goals;
  late GoalContributionRepositoryImpl repository;

  final createdAt = DateTime(2024, 1, 1);

  GoalContributionModel model({
    String id = 'c1',
    String goalId = 'g1',
    double amount = 50,
    DateTime? date,
  }) => GoalContributionModel(
    id: id,
    goalId: goalId,
    amount: amount,
    date: date ?? createdAt,
    createdAt: createdAt,
  );

  GoalContribution entity({
    String id = 'c1',
    String goalId = 'g1',
    double amount = 50,
  }) => GoalContribution(
    id: id,
    goalId: goalId,
    amount: amount,
    date: createdAt,
    createdAt: createdAt,
  );

  GoalModel goalModel({double savedCache = 0}) => GoalModel(
    id: 'g1',
    name: 'Laptop',
    targetAmount: 1000,
    statusIndex: GoalStatus.active.index,
    totalSavedCache: savedCache,
    createdAt: createdAt,
  );

  setUpAll(() {
    registerFallbackValue(_FakeContributionModel());
    registerFallbackValue(_FakeGoalModel());
  });

  setUp(() {
    contributions = MockContributionDataSource();
    goals = MockGoalDataSource();
    repository = GoalContributionRepositoryImpl(
      contributionDataSource: contributions,
      goalDataSource: goals,
    );

    when(() => contributions.saveContribution(any())).thenAnswer((_) async {});
    when(() => goals.saveGoal(any())).thenAnswer((_) async {});
    when(() => goals.getGoalById('g1')).thenAnswer((_) async => goalModel());
    when(
      () => contributions.getContributionsForGoal('g1'),
    ).thenAnswer((_) async => []);
  });

  GoalModel lastSavedGoal() =>
      verify(() => goals.saveGoal(captureAny())).captured.last as GoalModel;

  group('addContribution', () {
    test('saves the contribution and recomputes the goal total', () async {
      when(() => contributions.getContributionsForGoal('g1')).thenAnswer(
        (_) async => [model(id: 'c1', amount: 50), model(id: 'c2', amount: 75)],
      );

      final result = await repository.addContribution(entity(amount: 75));

      expect(rightOf(result).id, 'c1');
      verify(() => contributions.saveContribution(any())).called(1);
      expect(lastSavedGoal().totalSavedCache, 125);
    });

    test(
      'the recomputed total replaces the old cache rather than adding',
      () async {
        when(
          () => goals.getGoalById('g1'),
        ).thenAnswer((_) async => goalModel(savedCache: 9999));
        when(
          () => contributions.getContributionsForGoal('g1'),
        ).thenAnswer((_) async => [model(amount: 20)]);

        await repository.addContribution(entity(amount: 20));

        expect(lastSavedGoal().totalSavedCache, 20);
      },
    );

    test('the contribution still succeeds when the goal is missing', () async {
      when(() => goals.getGoalById('g1')).thenAnswer((_) async => null);

      final result = await repository.addContribution(entity());

      // A missing goal must not lose the user's contribution.
      expect(result.isRight(), isTrue);
      verifyNever(() => goals.saveGoal(any()));
    });

    test('maps a save failure to CacheFailure', () async {
      when(
        () => contributions.saveContribution(any()),
      ).thenThrow(Exception('disk'));

      expect(
        leftOf(await repository.addContribution(entity())).message,
        contains('Failed to add contribution'),
      );
    });
  });

  group('deleteContribution', () {
    test('deletes and recomputes the goal total from what remains', () async {
      when(
        () => contributions.getContributionById('c1'),
      ).thenAnswer((_) async => model());
      when(
        () => contributions.deleteContribution('c1'),
      ).thenAnswer((_) async {});
      when(
        () => contributions.getContributionsForGoal('g1'),
      ).thenAnswer((_) async => [model(id: 'c2', amount: 30)]);

      final result = await repository.deleteContribution('c1');

      expect(result.isRight(), isTrue);
      expect(lastSavedGoal().totalSavedCache, 30);
    });

    test('deleting the last contribution zeroes the cache', () async {
      when(
        () => contributions.getContributionById('c1'),
      ).thenAnswer((_) async => model());
      when(
        () => contributions.deleteContribution('c1'),
      ).thenAnswer((_) async {});
      when(
        () => contributions.getContributionsForGoal('g1'),
      ).thenAnswer((_) async => []);

      await repository.deleteContribution('c1');

      expect(lastSavedGoal().totalSavedCache, 0);
    });

    test('an unknown contribution is a CacheFailure', () async {
      when(
        () => contributions.getContributionById('ghost'),
      ).thenAnswer((_) async => null);

      expect(
        leftOf(await repository.deleteContribution('ghost')),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'Contribution not found.',
        ),
      );
      verifyNever(() => contributions.deleteContribution(any()));
    });

    test('maps a delete failure to CacheFailure', () async {
      when(
        () => contributions.getContributionById('c1'),
      ).thenAnswer((_) async => model());
      when(
        () => contributions.deleteContribution('c1'),
      ).thenThrow(Exception('locked'));

      expect(
        leftOf(await repository.deleteContribution('c1')).message,
        contains('Failed to delete contribution'),
      );
    });
  });

  group('updateContribution', () {
    test('saves the change and recomputes the goal total', () async {
      when(
        () => contributions.getContributionsForGoal('g1'),
      ).thenAnswer((_) async => [model(amount: 200)]);

      final result = await repository.updateContribution(entity(amount: 200));

      expect(rightOf(result).amount, 200);
      expect(lastSavedGoal().totalSavedCache, 200);
    });

    test('maps a write failure to CacheFailure', () async {
      when(
        () => contributions.saveContribution(any()),
      ).thenThrow(Exception('disk'));

      expect(
        leftOf(await repository.updateContribution(entity())).message,
        contains('Failed to update contribution'),
      );
    });
  });

  group('getContributionsForGoal', () {
    test('returns contributions newest first', () async {
      when(() => contributions.getContributionsForGoal('g1')).thenAnswer(
        (_) async => [
          model(id: 'old', date: DateTime(2024, 1, 1)),
          model(id: 'new', date: DateTime(2024, 6, 1)),
          model(id: 'mid', date: DateTime(2024, 3, 1)),
        ],
      );

      final result = rightOf(await repository.getContributionsForGoal('g1'));

      expect(result.map((c) => c.id), ['new', 'mid', 'old']);
    });

    test('an empty goal returns an empty list', () async {
      when(
        () => contributions.getContributionsForGoal('g1'),
      ).thenAnswer((_) async => []);

      expect(rightOf(await repository.getContributionsForGoal('g1')), isEmpty);
    });

    test('maps a read failure to CacheFailure', () async {
      when(
        () => contributions.getContributionsForGoal('g1'),
      ).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.getContributionsForGoal('g1')).message,
        contains('Failed to load contributions'),
      );
    });
  });

  group('getAllContributions', () {
    test('returns every contribution newest first', () async {
      when(() => contributions.getAllContributions()).thenAnswer(
        (_) async => [
          model(id: 'a', date: DateTime(2024, 2, 1)),
          model(id: 'b', date: DateTime(2024, 7, 1)),
        ],
      );

      final result = rightOf(await repository.getAllContributions());

      expect(result.map((c) => c.id), ['b', 'a']);
    });

    test('maps a read failure to CacheFailure', () async {
      when(
        () => contributions.getAllContributions(),
      ).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.getAllContributions()).message,
        contains('Failed to load contributions'),
      );
    });
  });

  group('auditGoalTotals', () {
    test('recomputes the cache for every goal', () async {
      final many = List.generate(
        3,
        (i) => GoalModel(
          id: 'g$i',
          name: 'Goal $i',
          targetAmount: 100,
          statusIndex: GoalStatus.active.index,
          totalSavedCache: 999,
          createdAt: createdAt,
        ),
      );
      when(() => goals.getGoals()).thenAnswer((_) async => many);
      for (final g in many) {
        when(() => goals.getGoalById(g.id)).thenAnswer((_) async => g);
        when(
          () => contributions.getContributionsForGoal(g.id),
        ).thenAnswer((_) async => [model(goalId: g.id, amount: 10)]);
      }

      final result = await repository.auditGoalTotals();

      expect(result.isRight(), isTrue);
      final saved = verify(
        () => goals.saveGoal(captureAny()),
      ).captured.cast<GoalModel>();
      expect(saved, hasLength(3));
      expect(saved.every((g) => g.totalSavedCache == 10), isTrue);
    });

    test('processes more goals than one batch', () async {
      // The audit walks goals in batches of 10; this proves the loop advances
      // past the first batch rather than stopping at it.
      final many = List.generate(
        23,
        (i) => GoalModel(
          id: 'g$i',
          name: 'Goal $i',
          targetAmount: 100,
          statusIndex: GoalStatus.active.index,
          totalSavedCache: 0,
          createdAt: createdAt,
        ),
      );
      when(() => goals.getGoals()).thenAnswer((_) async => many);
      for (final g in many) {
        when(() => goals.getGoalById(g.id)).thenAnswer((_) async => g);
        when(
          () => contributions.getContributionsForGoal(g.id),
        ).thenAnswer((_) async => [model(goalId: g.id, amount: 5)]);
      }

      await repository.auditGoalTotals();

      verify(() => goals.saveGoal(any())).called(23);
    });

    test('a single unreadable goal does not abort the whole audit', () async {
      final many = List.generate(
        2,
        (i) => GoalModel(
          id: 'g$i',
          name: 'Goal $i',
          targetAmount: 100,
          statusIndex: GoalStatus.active.index,
          totalSavedCache: 0,
          createdAt: createdAt,
        ),
      );
      when(() => goals.getGoals()).thenAnswer((_) async => many);
      when(() => goals.getGoalById('g0')).thenAnswer((_) async => null);
      when(
        () => contributions.getContributionsForGoal('g0'),
      ).thenAnswer((_) async => []);
      when(() => goals.getGoalById('g1')).thenAnswer((_) async => many[1]);
      when(
        () => contributions.getContributionsForGoal('g1'),
      ).thenAnswer((_) async => [model(goalId: 'g1', amount: 7)]);

      final result = await repository.auditGoalTotals();

      expect(result.isRight(), isTrue);
      expect(lastSavedGoal().totalSavedCache, 7);
    });

    test('maps a goal-list failure to CacheFailure', () async {
      when(() => goals.getGoals()).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.auditGoalTotals()).message,
        contains('Failed to audit goal total saved caches'),
      );
    });
  });
}
