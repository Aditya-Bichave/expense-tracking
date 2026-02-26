// ignore_for_file: directives_ordering

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/check_goal_achievement.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_contribution.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

// Mocks
class MockAddContributionUseCase extends Mock
    implements AddContributionUseCase {}

class MockUpdateContributionUseCase extends Mock
    implements UpdateContributionUseCase {}

class MockDeleteContributionUseCase extends Mock
    implements DeleteContributionUseCase {}

class MockCheckGoalAchievementUseCase extends Mock
    implements CheckGoalAchievementUseCase {}

class MockUuid extends Mock implements Uuid {}

// Fakes
class FakeAddContributionParams extends Fake implements AddContributionParams {}

class FakeUpdateContributionParams extends Fake
    implements UpdateContributionParams {}

class FakeDeleteContributionParams extends Fake
    implements DeleteContributionParams {}

class FakeCheckGoalParams extends Fake implements CheckGoalParams {}

void main() {
  late LogContributionBloc bloc;
  late MockAddContributionUseCase mockAddContributionUseCase;
  late MockUpdateContributionUseCase mockUpdateContributionUseCase;
  late MockDeleteContributionUseCase mockDeleteContributionUseCase;
  late MockCheckGoalAchievementUseCase mockCheckGoalAchievementUseCase;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(FakeAddContributionParams());
    registerFallbackValue(FakeUpdateContributionParams());
    registerFallbackValue(FakeDeleteContributionParams());
    registerFallbackValue(FakeCheckGoalParams());
  });

  setUp(() {
    mockAddContributionUseCase = MockAddContributionUseCase();
    mockUpdateContributionUseCase = MockUpdateContributionUseCase();
    mockDeleteContributionUseCase = MockDeleteContributionUseCase();
    mockCheckGoalAchievementUseCase = MockCheckGoalAchievementUseCase();
    mockUuid = MockUuid();

    when(() => mockUuid.v4()).thenReturn('new-id');

    // Default mock behavior for check achievement
    when(
      () => mockCheckGoalAchievementUseCase(any()),
    ).thenAnswer((_) async => const Right(false));

    bloc = LogContributionBloc(
      addContributionUseCase: mockAddContributionUseCase,
      updateContributionUseCase: mockUpdateContributionUseCase,
      deleteContributionUseCase: mockDeleteContributionUseCase,
      checkGoalAchievementUseCase: mockCheckGoalAchievementUseCase,
      uuid: mockUuid,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tContribution = GoalContribution(
    id: 'c1',
    goalId: 'g1',
    amount: 100.0,
    date: DateTime(2023, 1, 1),
    note: 'Note',
    createdAt: DateTime(2023, 1, 1),
  );

  group('LogContributionBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, LogContributionStatus.initial);
      expect(bloc.state.goalId, '');
    });

    blocTest<LogContributionBloc, LogContributionState>(
      'InitializeContribution sets state correctly',
      build: () => bloc,
      act: (bloc) => bloc.add(const InitializeContribution(goalId: 'g1')),
      expect: () => [
        isA<LogContributionState>()
            .having((s) => s.goalId, 'goalId', 'g1')
            .having((s) => s.status, 'status', LogContributionStatus.initial),
      ],
    );

    blocTest<LogContributionBloc, LogContributionState>(
      'SaveContribution (Add) emits [loading, success] on success',
      setUp: () {
        when(
          () => mockAddContributionUseCase(any()),
        ).thenAnswer((_) async => Right(tContribution));
      },
      build: () => bloc,
      seed: () => LogContributionState(
        goalId: 'g1',
        status: LogContributionStatus.initial,
      ),
      act: (bloc) => bloc.add(
        SaveContribution(
          amount: 100.0,
          date: DateTime(2023, 1, 1),
          note: 'Note',
        ),
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
      verify: (_) {
        verify(() => mockAddContributionUseCase(any())).called(1);
        verify(() => mockCheckGoalAchievementUseCase(any())).called(1);
      },
    );

    blocTest<LogContributionBloc, LogContributionState>(
      'SaveContribution (Edit) emits [loading, success] on success',
      setUp: () {
        when(
          () => mockUpdateContributionUseCase(any()),
        ).thenAnswer((_) async => Right(tContribution));
      },
      build: () => bloc,
      seed: () => LogContributionState(
        goalId: 'g1',
        initialContribution: tContribution,
        status: LogContributionStatus.initial,
      ),
      act: (bloc) =>
          bloc.add(SaveContribution(amount: 200.0, date: DateTime(2023, 1, 1))),
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
      verify: (_) {
        verify(() => mockUpdateContributionUseCase(any())).called(1);
      },
    );

    blocTest<LogContributionBloc, LogContributionState>(
      'DeleteContribution emits [loading, success] on success',
      setUp: () {
        when(
          () => mockDeleteContributionUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      seed: () => LogContributionState(
        goalId: 'g1',
        initialContribution: tContribution,
        status: LogContributionStatus.initial,
      ),
      act: (bloc) => bloc.add(const DeleteContribution()),
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

    blocTest<LogContributionBloc, LogContributionState>(
      'DeleteContribution emits error if not editing',
      build: () => bloc,
      seed: () => LogContributionState(
        goalId: 'g1',
        status: LogContributionStatus.initial,
      ),
      act: (bloc) => bloc.add(const DeleteContribution()),
      expect: () => [
        isA<LogContributionState>()
            .having((s) => s.status, 'status', LogContributionStatus.error)
            .having(
              (s) => s.errorMessage,
              'message',
              contains('Cannot delete'),
            ),
      ],
    );
  });
}
