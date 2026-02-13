import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
import 'package:expense_tracker/features/goals/domain/usecases/archive_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGoalsUseCase extends Mock implements GetGoalsUseCase {}

class MockArchiveGoalUseCase extends Mock implements ArchiveGoalUseCase {}

class MockDeleteGoalUseCase extends Mock implements DeleteGoalUseCase {}

void main() {
  late GoalListBloc bloc;
  late MockGetGoalsUseCase mockGetGoalsUseCase;
  late MockArchiveGoalUseCase mockArchiveGoalUseCase;
  late MockDeleteGoalUseCase mockDeleteGoalUseCase;
  late StreamController<DataChangedEvent> dataChangeController;

  final tGoal = Goal(
    id: '1',
    name: 'Test Goal',
    targetAmount: 1000,
    status: GoalStatus.active,
    totalSaved: 100,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ArchiveGoalParams(id: ''));
    registerFallbackValue(const DeleteGoalParams(id: ''));
  });

  setUp(() {
    mockGetGoalsUseCase = MockGetGoalsUseCase();
    mockArchiveGoalUseCase = MockArchiveGoalUseCase();
    mockDeleteGoalUseCase = MockDeleteGoalUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    bloc = GoalListBloc(
      getGoalsUseCase: mockGetGoalsUseCase,
      archiveGoalUseCase: mockArchiveGoalUseCase,
      deleteGoalUseCase: mockDeleteGoalUseCase,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() {
    bloc.close();
    dataChangeController.close();
  });

  group('LoadGoals', () {
    blocTest<GoalListBloc, GoalListState>(
      'emits [loading, success] when successful',
      build: () {
        when(() => mockGetGoalsUseCase(any()))
            .thenAnswer((_) async => Right([tGoal]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [
        const GoalListState(status: GoalListStatus.loading),
        GoalListState(status: GoalListStatus.success, goals: [tGoal]),
      ],
    );

    blocTest<GoalListBloc, GoalListState>(
      'emits [loading, error] when failure',
      build: () {
        when(() => mockGetGoalsUseCase(any()))
            .thenAnswer((_) async => Left(CacheFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [
        const GoalListState(status: GoalListStatus.loading),
        isA<GoalListState>()
            .having((s) => s.status, 'status', GoalListStatus.error)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('Database Error')),
      ],
    );
  });

  group('ArchiveGoal', () {
    blocTest<GoalListBloc, GoalListState>(
      'emits optimistic update and then success',
      seed: () => GoalListState(status: GoalListStatus.success, goals: [tGoal]),
      build: () {
        when(() => mockArchiveGoalUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(ArchiveGoal(goalId: tGoal.id)),
      expect: () => [
        const GoalListState(
            status: GoalListStatus.success, goals: []), // Optimistic removal
      ],
      verify: (_) {
        verify(() => mockArchiveGoalUseCase(ArchiveGoalParams(id: tGoal.id)))
            .called(1);
      },
    );

    blocTest<GoalListBloc, GoalListState>(
      'emits optimistic update and then reverts on failure',
      seed: () => GoalListState(status: GoalListStatus.success, goals: [tGoal]),
      build: () {
        when(() => mockArchiveGoalUseCase(any()))
            .thenAnswer((_) async => Left(CacheFailure('Fail')));
        when(() => mockGetGoalsUseCase(any())) // Reload triggered on failure
            .thenAnswer((_) async => Right([tGoal]));
        return bloc;
      },
      act: (bloc) => bloc.add(ArchiveGoal(goalId: tGoal.id)),
      expect: () => [
        const GoalListState(
            status: GoalListStatus.success, goals: []), // Optimistic removal
        isA<GoalListState>()
            .having((s) => s.status, 'status', GoalListStatus.error)
            .having((s) => s.goals, 'goals', isEmpty), // Error state
        const GoalListState(
            status: GoalListStatus.loading, goals: []), // Reload loading
        GoalListState(
            status: GoalListStatus.success, goals: [tGoal]), // Reload success
      ],
    );
  });

  group('DeleteGoal', () {
    blocTest<GoalListBloc, GoalListState>(
      'emits optimistic update and then success',
      seed: () => GoalListState(status: GoalListStatus.success, goals: [tGoal]),
      build: () {
        when(() => mockDeleteGoalUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(DeleteGoal(goalId: tGoal.id)),
      expect: () => [
        const GoalListState(
            status: GoalListStatus.success, goals: []), // Optimistic removal
      ],
      verify: (_) {
        verify(() => mockDeleteGoalUseCase(DeleteGoalParams(id: tGoal.id)))
            .called(1);
      },
    );
  });

  group('DataChangedEvent', () {
    blocTest<GoalListBloc, GoalListState>(
      'triggers reload on goal change',
      build: () {
        when(() => mockGetGoalsUseCase(any()))
            .thenAnswer((_) async => Right([tGoal]));
        return bloc;
      },
      act: (bloc) async {
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.goal, reason: DataChangeReason.updated));
      },
      expect: () => [
        const GoalListState(status: GoalListStatus.loading),
        GoalListState(status: GoalListStatus.success, goals: [tGoal]),
      ],
    );

    blocTest<GoalListBloc, GoalListState>(
      'resets state on system reset',
      build: () {
        when(() => mockGetGoalsUseCase(any()))
            .thenAnswer((_) async => Right([tGoal]));
        return bloc;
      },
      act: (bloc) async {
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.system, reason: DataChangeReason.reset));
      },
      expect: () => [
        const GoalListState(status: GoalListStatus.initial, goals: []),
        const GoalListState(status: GoalListStatus.loading, goals: []),
        GoalListState(status: GoalListStatus.success, goals: [tGoal]),
      ],
    );
  });
}
