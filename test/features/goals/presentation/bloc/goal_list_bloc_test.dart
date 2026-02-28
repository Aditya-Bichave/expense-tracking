import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/usecases/archive_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGoalsUseCase extends Mock implements GetGoalsUseCase {}

class MockArchiveGoalUseCase extends Mock implements ArchiveGoalUseCase {}

class MockDeleteGoalUseCase extends Mock implements DeleteGoalUseCase {}

void main() {
  late MockGetGoalsUseCase mockGetGoalsUseCase;
  late MockArchiveGoalUseCase mockArchiveGoalUseCase;
  late MockDeleteGoalUseCase mockDeleteGoalUseCase;
  late Stream<DataChangedEvent> dataChangeStream;

  setUp(() {
    mockGetGoalsUseCase = MockGetGoalsUseCase();
    mockArchiveGoalUseCase = MockArchiveGoalUseCase();
    mockDeleteGoalUseCase = MockDeleteGoalUseCase();
    dataChangeStream = const Stream.empty();
    registerFallbackValue(NoParams());
    registerFallbackValue(const DeleteGoalParams(id: '1'));
  });

  final tGoal = Goal(
    id: '1',
    name: 'Vacation',
    targetAmount: 1000,
    status: GoalStatus.active,
    totalSaved: 0,
    createdAt: DateTime.now(),
  );

  blocTest<GoalListBloc, GoalListState>(
    'emits [loading, success] when LoadGoals is added and succeeds',
    build: () {
      when(
        () => mockGetGoalsUseCase(any()),
      ).thenAnswer((_) async => Right([tGoal]));
      return GoalListBloc(
        getGoalsUseCase: mockGetGoalsUseCase,
        archiveGoalUseCase: mockArchiveGoalUseCase,
        deleteGoalUseCase: mockDeleteGoalUseCase,
        dataChangeStream: dataChangeStream,
      );
    },
    act: (bloc) => bloc.add(const LoadGoals()),
    expect: () => [
      const GoalListState(
        status: GoalListStatus.loading,
      ), // Fixed: Removed clearError
      isA<GoalListState>()
          .having((s) => s.status, 'status', GoalListStatus.success)
          .having((s) => s.goals.length, 'goals', 1),
    ],
  );

  blocTest<GoalListBloc, GoalListState>(
    'emits optimistic delete and then success (via stream) when DeleteGoal is added',
    build: () {
      when(
        () => mockDeleteGoalUseCase(any()),
      ).thenAnswer((_) async => const Right(null));
      return GoalListBloc(
        getGoalsUseCase: mockGetGoalsUseCase,
        archiveGoalUseCase: mockArchiveGoalUseCase,
        deleteGoalUseCase: mockDeleteGoalUseCase,
        dataChangeStream: dataChangeStream,
      );
    },
    seed: () => GoalListState(status: GoalListStatus.success, goals: [tGoal]),
    act: (bloc) => bloc.add(const DeleteGoal(goalId: '1')),
    expect: () => [
      isA<GoalListState>()
          .having((s) => s.goals.isEmpty, 'goals', true)
          .having((s) => s.status, 'status', GoalListStatus.success),
    ],
    verify: (_) {
      verify(() => mockDeleteGoalUseCase(any())).called(1);
    },
  );
}
