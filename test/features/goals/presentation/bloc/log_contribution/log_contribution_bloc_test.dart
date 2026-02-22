import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/check_goal_achievement.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_contribution.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockAddContributionUseCase extends Mock
    implements AddContributionUseCase {}

class MockUpdateContributionUseCase extends Mock
    implements UpdateContributionUseCase {}

class MockDeleteContributionUseCase extends Mock
    implements DeleteContributionUseCase {}

class MockCheckGoalAchievementUseCase extends Mock
    implements CheckGoalAchievementUseCase {}

void main() {
  late MockAddContributionUseCase mockAddContributionUseCase;
  late MockUpdateContributionUseCase mockUpdateContributionUseCase;
  late MockDeleteContributionUseCase mockDeleteContributionUseCase;
  late MockCheckGoalAchievementUseCase mockCheckGoalAchievementUseCase;

  setUpAll(() {
    registerFallbackValue(
      AddContributionParams(goalId: 'g1', amount: 10, date: DateTime.now()),
    );
    registerFallbackValue(CheckGoalParams(goalId: 'g1'));
  });

  setUp(() {
    mockAddContributionUseCase = MockAddContributionUseCase();
    mockUpdateContributionUseCase = MockUpdateContributionUseCase();
    mockDeleteContributionUseCase = MockDeleteContributionUseCase();
    mockCheckGoalAchievementUseCase = MockCheckGoalAchievementUseCase();

    final getIt = GetIt.instance;
    // Ensure we start with a clean slate or check registration
    if (getIt.isRegistered<Uuid>()) {
      getIt.unregister<Uuid>();
    }
    getIt.registerSingleton<Uuid>(const Uuid());
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('LogContributionBloc', () {
    blocTest<LogContributionBloc, LogContributionState>(
      'emits success when SaveContribution is added',
      build: () {
        when(() => mockAddContributionUseCase(any())).thenAnswer(
          (_) async => Right(
            GoalContribution(
              id: 'c1',
              goalId: 'g1',
              amount: 100,
              date: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          ),
        );
        when(
          () => mockCheckGoalAchievementUseCase(any()),
        ).thenAnswer((_) async => const Right(false));
        return LogContributionBloc(
          addContributionUseCase: mockAddContributionUseCase,
          updateContributionUseCase: mockUpdateContributionUseCase,
          deleteContributionUseCase: mockDeleteContributionUseCase,
          checkGoalAchievementUseCase: mockCheckGoalAchievementUseCase,
        );
      },
      seed: () => LogContributionState(
        goalId: 'g1',
        status: LogContributionStatus.initial,
      ),
      act: (bloc) => bloc.add(
        SaveContribution(amount: 100, date: DateTime.now(), note: 'Test'),
      ),
      expect: () => [
        isA<LogContributionState>().having(
          (s) => s.status,
          'status',
          LogContributionStatus.loading,
        ),
        isA<LogContributionState>().having(
          (s) => s.status,
          'status',
          LogContributionStatus.success,
        ),
      ],
    );
  });
}
