import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';

// Mocks
class MockGoalLocalDataSource implements GoalLocalDataSource {
  final List<GoalModel> _goals = [];

  MockGoalLocalDataSource(int numGoals) {
    for (int i = 0; i < numGoals; i++) {
      _goals.add(
        GoalModel(
          id: 'goal_$i',
          name: 'Goal $i',
          targetAmount: 1000,
          targetDate: DateTime.now(),
          iconName: 'icon_$i',
          description: 'Description $i',
          statusIndex: 0,
          createdAt: DateTime.now(),
          achievedAt: null,
          totalSavedCache: 0,
        ),
      );
    }
  }

  @override
  Future<List<GoalModel>> getGoals() async {
    await Future.delayed(
      const Duration(milliseconds: 10),
    ); // simulate DB access
    return _goals;
  }

  @override
  Future<GoalModel?> getGoalById(String id) async {
    await Future.delayed(
      const Duration(milliseconds: 10),
    ); // simulate DB access
    try {
      return _goals.firstWhere((g) => g.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<void> saveGoal(GoalModel goal) async {
    await Future.delayed(
      const Duration(milliseconds: 10),
    ); // simulate DB access
  }

  @override
  Future<void> deleteGoal(String id) async {}

  @override
  Future<void> clearAllGoals() async {}
}

class MockGoalContributionLocalDataSource
    implements GoalContributionLocalDataSource {
  @override
  Future<List<GoalContributionModel>> getContributionsForGoal(
    String goalId,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 10),
    ); // simulate DB access
    return [
      GoalContributionModel(
        id: 'c1',
        goalId: goalId,
        amount: 100,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      GoalContributionModel(
        id: 'c2',
        goalId: goalId,
        amount: 200,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> saveContribution(GoalContributionModel contribution) async {}
  @override
  Future<void> deleteContribution(String id) async {}
  @override
  Future<GoalContributionModel?> getContributionById(String id) async => null;
  @override
  Future<List<GoalContributionModel>> getAllContributions() async => [];

  @override
  Future<void> clearAllContributions() async {}
  @override
  Future<void> deleteContributions(List<String> ids) async {}
}

class BenchmarkGoalContributionRepository {
  final GoalContributionLocalDataSource contributionDataSource;
  final GoalLocalDataSource goalDataSource;

  BenchmarkGoalContributionRepository({
    required this.contributionDataSource,
    required this.goalDataSource,
  });

  Future<Either<Failure, void>> _updateGoalTotalSavedCache(
    String goalId,
  ) async {
    try {
      final contributions = await contributionDataSource
          .getContributionsForGoal(goalId);
      final double newTotalSaved = contributions.fold(
        0.0,
        (sum, c) => sum + c.amount,
      );
      final goalModel = await goalDataSource.getGoalById(goalId);
      if (goalModel == null) return const Left(CacheFailure("Goal not found"));
      final updatedGoalModel = GoalModel(
        id: goalModel.id,
        name: goalModel.name,
        targetAmount: goalModel.targetAmount,
        targetDate: goalModel.targetDate,
        iconName: goalModel.iconName,
        description: goalModel.description,
        statusIndex: goalModel.statusIndex,
        createdAt: goalModel.createdAt,
        achievedAt: goalModel.achievedAt,
        totalSavedCache: newTotalSaved,
      );
      await goalDataSource.saveGoal(updatedGoalModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure("Error"));
    }
  }

  Future<void> auditGoalTotalsSequential() async {
    final goals = await goalDataSource.getGoals();
    for (final goal in goals) {
      final result = await _updateGoalTotalSavedCache(goal.id);
      if (result.isLeft()) {
        // failed
      }
    }
  }

  Future<void> auditGoalTotalsConcurrent() async {
    final goals = await goalDataSource.getGoals();
    const int batchSize = 10;
    for (int i = 0; i < goals.length; i += batchSize) {
      final batch = goals.skip(i).take(batchSize);
      await Future.wait(
        batch.map((goal) async {
          final result = await _updateGoalTotalSavedCache(goal.id);
          if (result.isLeft()) {
            // failed
          }
        }),
      );
    }
  }
}

void main() {
  test(
    'Benchmark Sequential vs Concurrent auditGoalTotals',
    skip: true,
    () async {
      final repo = BenchmarkGoalContributionRepository(
        contributionDataSource: MockGoalContributionLocalDataSource(),
        goalDataSource: MockGoalLocalDataSource(50), // 50 goals
      );

      // Warmup
      await repo.auditGoalTotalsSequential();
      await repo.auditGoalTotalsConcurrent();

      // Benchmark sequential
      final startSeq = DateTime.now();
      await repo.auditGoalTotalsSequential();
      final endSeq = DateTime.now();
      final seqTime = endSeq.difference(startSeq).inMilliseconds;

      // Benchmark concurrent
      final startConc = DateTime.now();
      await repo.auditGoalTotalsConcurrent();
      final endConc = DateTime.now();
      final concTime = endConc.difference(startConc).inMilliseconds;

      print('--- BENCHMARK RESULTS ---');
      print('Sequential: $seqTime ms');
      print('Concurrent: $concTime ms');
      print(
        'Improvement: ${((seqTime - concTime) / seqTime * 100).toStringAsFixed(2)}% faster',
      );
    },
  );
}
