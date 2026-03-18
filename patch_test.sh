cat << 'TEST' >> test/features/goals/data/repositories/goal_contribution_repository_impl_test.dart

  group('auditGoalTotals', () {
    test('should execute updates for all goals concurrently', () async {
      when(() => mockGoalDataSource.getGoals()).thenAnswer((_) async => [tGoal, tGoal.copyWith(id: 'g2')]);
      when(() => mockDataSource.getContributionsForGoal('g1')).thenAnswer((_) async => [tContribution]);
      when(() => mockDataSource.getContributionsForGoal('g2')).thenAnswer((_) async => []);
      when(() => mockGoalDataSource.updateGoalTotalSaved('g1', 50.0)).thenAnswer((_) async => {});
      when(() => mockGoalDataSource.updateGoalTotalSaved('g2', 0.0)).thenAnswer((_) async => {});

      final result = await repository.auditGoalTotals();
      expect(result.isRight(), isTrue);
      verify(() => mockGoalDataSource.updateGoalTotalSaved('g1', 50.0)).called(1);
      verify(() => mockGoalDataSource.updateGoalTotalSaved('g2', 0.0)).called(1);
    });

    test('should log warning if an update fails but return Right', () async {
      when(() => mockGoalDataSource.getGoals()).thenAnswer((_) async => [tGoal]);
      when(() => mockDataSource.getContributionsForGoal('g1')).thenAnswer((_) async => [tContribution]);
      when(() => mockGoalDataSource.updateGoalTotalSaved('g1', 50.0)).thenThrow(Exception('Update error'));

      final result = await repository.auditGoalTotals();
      expect(result.isRight(), isTrue);
    });
  });
TEST
