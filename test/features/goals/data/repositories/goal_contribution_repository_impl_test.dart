import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_contribution_repository_impl.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalContributionLocalDataSource extends Mock
    implements GoalContributionLocalDataSource {}

class MockGoalLocalDataSource extends Mock implements GoalLocalDataSource {}

void main() {
  late GoalContributionRepositoryImpl repository;
  late MockGoalContributionLocalDataSource mockContributionDataSource;
  late MockGoalLocalDataSource mockGoalDataSource;

  setUp(() {
    mockContributionDataSource = MockGoalContributionLocalDataSource();
    mockGoalDataSource = MockGoalLocalDataSource();
    repository = GoalContributionRepositoryImpl(
      contributionDataSource: mockContributionDataSource,
      goalDataSource: mockGoalDataSource,
    );
    registerFallbackValue(
      GoalContributionModel(
        id: '1',
        goalId: 'g1',
        amount: 50,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      GoalModel(
        id: 'g1',
        name: 'G',
        targetAmount: 100,
        statusIndex: 0,
        totalSavedCache: 0,
        createdAt: DateTime.now(),
      ),
    );
  });

  final tContribution = GoalContribution(
    id: '1',
    goalId: 'g1',
    amount: 50,
    date: DateTime.now(),
    createdAt: DateTime.now(),
  );

  final tContributionValid = tContribution.copyWith(
    date: DateTime.now(),
    createdAt: DateTime.now(),
  );

  group('addContribution', () {
    test('should save contribution and update goal cache', () async {
      when(
        () => mockContributionDataSource.saveContribution(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockContributionDataSource.getContributionsForGoal('g1'),
      ).thenAnswer(
        (_) async => [GoalContributionModel.fromEntity(tContributionValid)],
      );
      when(() => mockGoalDataSource.getGoalById('g1')).thenAnswer(
        (_) async => GoalModel(
          id: 'g1',
          name: 'G',
          targetAmount: 100,
          statusIndex: 0,
          totalSavedCache: 0,
          createdAt: DateTime.now(),
        ),
      );
      when(() => mockGoalDataSource.saveGoal(any())).thenAnswer((_) async {});

      final result = await repository.addContribution(tContributionValid);

      expect(result.isRight(), true);
      verify(
        () => mockContributionDataSource.saveContribution(any()),
      ).called(1);
      verify(() => mockGoalDataSource.saveGoal(any())).called(1);
    });
  });

  group('auditGoalTotals', () {
    test('should fetch all goals and update cache concurrently', () async {
      final goals = [
        GoalModel(
          id: 'g1',
          name: 'G1',
          targetAmount: 100,
          statusIndex: 0,
          totalSavedCache: 0,
          createdAt: DateTime.now(),
        ),
        GoalModel(
          id: 'g2',
          name: 'G2',
          targetAmount: 200,
          statusIndex: 0,
          totalSavedCache: 0,
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockGoalDataSource.getGoals()).thenAnswer((_) async => goals);

      when(
        () => mockContributionDataSource.getContributionsForGoal('g1'),
      ).thenAnswer(
        (_) async => [
          GoalContributionModel(
            id: 'c1',
            goalId: 'g1',
            amount: 50,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ],
      );

      when(
        () => mockContributionDataSource.getContributionsForGoal('g2'),
      ).thenAnswer(
        (_) async => [
          GoalContributionModel(
            id: 'c2',
            goalId: 'g2',
            amount: 150,
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ],
      );

      when(() => mockGoalDataSource.getGoalById(any())).thenAnswer((inv) async {
        final id = inv.positionalArguments[0] as String;
        return goals.firstWhere((g) => g.id == id);
      });

      final capturedGoals = <GoalModel>[];
      when(() => mockGoalDataSource.saveGoal(any())).thenAnswer((inv) async {
        capturedGoals.add(inv.positionalArguments[0] as GoalModel);
      });

      final result = await repository.auditGoalTotals();

      expect(result.isRight(), true);
      verify(() => mockGoalDataSource.getGoals()).called(1);
      verify(
        () => mockContributionDataSource.getContributionsForGoal('g1'),
      ).called(1);
      verify(
        () => mockContributionDataSource.getContributionsForGoal('g2'),
      ).called(1);
      verify(() => mockGoalDataSource.saveGoal(any())).called(2);

      // Assert totalSavedCache values
      final Map<String, double> expectedTotals = {'g1': 50.0, 'g2': 150.0};

      for (final savedGoal in capturedGoals) {
        expect(savedGoal.totalSavedCache, expectedTotals[savedGoal.id]);
      }
    });

    test(
      'should log warning when goal cache update fails but continue auditing',
      () async {
        final goals = [
          GoalModel(
            id: 'g1',
            name: 'G1',
            targetAmount: 100,
            statusIndex: 0,
            totalSavedCache: 0,
            createdAt: DateTime.now(),
          ),
          GoalModel(
            id: 'g2',
            name: 'G2',
            targetAmount: 200,
            statusIndex: 0,
            totalSavedCache: 0,
            createdAt: DateTime.now(),
          ),
        ];

        when(
          () => mockGoalDataSource.getGoals(),
        ).thenAnswer((_) async => goals);

        // Setup g1 to fail
        when(
          () => mockContributionDataSource.getContributionsForGoal('g1'),
        ).thenThrow(Exception('Simulated error'));

        // Setup g2 to succeed
        when(
          () => mockContributionDataSource.getContributionsForGoal('g2'),
        ).thenAnswer(
          (_) async => [
            GoalContributionModel(
              id: 'c2',
              goalId: 'g2',
              amount: 150,
              date: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          ],
        );

        when(() => mockGoalDataSource.getGoalById(any())).thenAnswer((
          inv,
        ) async {
          final id = inv.positionalArguments[0] as String;
          return goals.firstWhere((g) => g.id == id);
        });

        when(() => mockGoalDataSource.saveGoal(any())).thenAnswer((_) async {});

        final result = await repository.auditGoalTotals();

        expect(result.isRight(), true);
        verify(() => mockGoalDataSource.getGoals()).called(1);

        // Verify g2 was still processed and saved successfully despite g1 failing
        verify(
          () => mockContributionDataSource.getContributionsForGoal('g2'),
        ).called(1);
        verify(
          () => mockGoalDataSource.saveGoal(any()),
        ).called(1); // Only g2 is saved
      },
    );

    test('should return CacheFailure when getting goals throws', () async {
      when(
        () => mockGoalDataSource.getGoals(),
      ).thenThrow(Exception('Failed to get goals'));

      final result = await repository.auditGoalTotals();

      expect(result.isLeft(), true);
    });
  });

  group('auditGoalTotals', () {
    test('should execute updates for all goals concurrently', () async {
      final tGoalModel = GoalModel(id: 'g1', name: 'g1', targetAmount: 100, targetDate: null, statusIndex: 0, totalSavedCache: 0, createdAt: DateTime.now(), iconName: 'icon');
      final tGoalModel2 = GoalModel(id: 'g2', name: 'g2', targetAmount: 100, targetDate: null, statusIndex: 0, totalSavedCache: 0, createdAt: DateTime.now(), iconName: 'icon');
      final tContributionModel = GoalContributionModel(id: 'c1', amount: 50.0, date: DateTime.now(), goalId: 'g1', createdAt: DateTime.now());

      when(() => mockGoalDataSource.getGoals()).thenAnswer((_) async => [tGoalModel, tGoalModel2]);
      when(() => mockGoalDataSource.getGoalById('g1')).thenAnswer((_) async => tGoalModel);
      when(() => mockGoalDataSource.getGoalById('g2')).thenAnswer((_) async => tGoalModel2);
      when(() => mockContributionDataSource.getContributionsForGoal('g1')).thenAnswer((_) async => [tContributionModel]);
      when(() => mockContributionDataSource.getContributionsForGoal('g2')).thenAnswer((_) async => []);
      when(() => mockGoalDataSource.saveGoal(any())).thenAnswer((_) async => {});

      final result = await repository.auditGoalTotals();
      expect(result.isRight(), isTrue);
      verify(() => mockGoalDataSource.saveGoal(any())).called(2);
    });

    test('should log warning if an update fails but return Right', () async {
      final tGoalModel = GoalModel(id: 'g1', name: 'g1', targetAmount: 100, targetDate: null, statusIndex: 0, totalSavedCache: 0, createdAt: DateTime.now(), iconName: 'icon');
      final tContributionModel = GoalContributionModel(id: 'c1', amount: 50.0, date: DateTime.now(), goalId: 'g1', createdAt: DateTime.now());

      when(() => mockGoalDataSource.getGoals()).thenAnswer((_) async => [tGoalModel]);
      when(() => mockGoalDataSource.getGoalById('g1')).thenAnswer((_) async => tGoalModel);
      when(() => mockContributionDataSource.getContributionsForGoal('g1')).thenAnswer((_) async => [tContributionModel]);
      when(() => mockGoalDataSource.saveGoal(any())).thenThrow(Exception('Update error'));

      final result = await repository.auditGoalTotals();
      expect(result.isRight(), isTrue);
    });

    test('should return Left on overall exception', () async {
      when(() => mockGoalDataSource.getGoals()).thenThrow(Exception('Overall error'));
      final result = await repository.auditGoalTotals();
      expect(result.isLeft(), isTrue);
    });
  });
}
