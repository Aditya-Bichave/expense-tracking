import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/check_goal_achievement.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAddContributionUseCase extends Mock
    implements AddContributionUseCase {}

class MockUpdateContributionUseCase extends Mock
    implements UpdateContributionUseCase {}

class MockDeleteContributionUseCase extends Mock
    implements DeleteContributionUseCase {}

class MockCheckGoalAchievementUseCase extends Mock
    implements CheckGoalAchievementUseCase {}

void main() {
  late MockAddContributionUseCase addUseCase;
  late MockUpdateContributionUseCase updateUseCase;
  late MockDeleteContributionUseCase deleteUseCase;
  late MockCheckGoalAchievementUseCase checkUseCase;

  setUpAll(() {
    registerFallbackValue(
      AddContributionParams(goalId: 'g', amount: 1, date: DateTime(2024, 1, 1)),
    );
    registerFallbackValue(
      UpdateContributionParams(
        contribution: GoalContribution(
          id: '0',
          goalId: 'g',
          amount: 1,
          date: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
        ),
      ),
    );
    registerFallbackValue(const DeleteContributionParams(id: '0'));
    registerFallbackValue(const CheckGoalParams(goalId: 'g'));
  });

  setUp(() async {
    await sl.reset();
    sl.registerSingleton<Uuid>(const Uuid());
    addUseCase = MockAddContributionUseCase();
    updateUseCase = MockUpdateContributionUseCase();
    deleteUseCase = MockDeleteContributionUseCase();
    checkUseCase = MockCheckGoalAchievementUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test(
    'emits success only after achievement check completes when saving contribution',
    () async {
      const goalId = 'goal-1';
      final contribution = GoalContribution(
        id: 'c1',
        goalId: goalId,
        amount: 10,
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      );
      var checkCompleted = false;

      when(
        () => addUseCase(any()),
      ).thenAnswer((_) async => Right(contribution));
      when(() => checkUseCase(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        checkCompleted = true;
        return const Right(false);
      });

      final bloc = LogContributionBloc(
        addContributionUseCase: addUseCase,
        updateContributionUseCase: updateUseCase,
        deleteContributionUseCase: deleteUseCase,
        checkGoalAchievementUseCase: checkUseCase,
      );

      bloc.add(const InitializeContribution(goalId: goalId));
      bloc.add(SaveContribution(amount: 10, date: DateTime(2024, 1, 1)));

      await expectLater(
        bloc.stream.skip(1),
        emitsInOrder([
          predicate<LogContributionState>(
            (s) => s.status == LogContributionStatus.loading,
          ),
          predicate<LogContributionState>((s) {
            expect(checkCompleted, isTrue);
            return s.status == LogContributionStatus.success;
          }),
        ]),
      );

      await bloc.close();
    },
  );
}
