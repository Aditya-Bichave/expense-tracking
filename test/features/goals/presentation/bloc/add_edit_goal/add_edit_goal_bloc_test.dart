// ignore_for_file: directives_ordering

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

// Mocks
class MockAddGoalUseCase extends Mock implements AddGoalUseCase {}

class MockUpdateGoalUseCase extends Mock implements UpdateGoalUseCase {}

class MockUuid extends Mock implements Uuid {}

class FakeAddGoalParams extends Fake implements AddGoalParams {}

class FakeUpdateGoalParams extends Fake implements UpdateGoalParams {}

class FakeGoal extends Fake implements Goal {}

void main() {
  late AddEditGoalBloc bloc;
  late MockAddGoalUseCase mockAddGoalUseCase;
  late MockUpdateGoalUseCase mockUpdateGoalUseCase;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(FakeAddGoalParams());
    registerFallbackValue(FakeUpdateGoalParams());
    registerFallbackValue(FakeGoal());
  });

  setUp(() {
    mockAddGoalUseCase = MockAddGoalUseCase();
    mockUpdateGoalUseCase = MockUpdateGoalUseCase();
    mockUuid = MockUuid();

    // Refactored bloc to accept Uuid for testing.
    when(() => mockUuid.v4()).thenReturn('new-goal-id');

    bloc = AddEditGoalBloc(
      addGoalUseCase: mockAddGoalUseCase,
      updateGoalUseCase: mockUpdateGoalUseCase,
      uuid: mockUuid,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tGoal = Goal(
    id: '1',
    name: 'New Car',
    targetAmount: 20000.0,
    targetDate: DateTime(2023, 12, 31),
    iconName: 'car',
    description: 'Saving for a car',
    status: GoalStatus.active,
    totalSaved: 0.0,
    createdAt: DateTime(2023, 1, 1),
  );

  group('AddEditGoalBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, AddEditGoalStatus.initial);
      expect(bloc.state.isEditing, false);
    });

    blocTest<AddEditGoalBloc, AddEditGoalState>(
      'emits [loading, success] when SaveGoal succeeds (Add Mode)',
      setUp: () {
        when(
          () => mockAddGoalUseCase(any()),
        ).thenAnswer((_) async => Right(tGoal));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(
        const SaveGoal(
          name: 'New Car',
          targetAmount: 20000.0,
          targetDate: null,
          iconName: 'car',
          description: 'Saving for a car',
        ),
      ),
      expect: () => [
        isA<AddEditGoalState>().having(
          (s) => s.status,
          'status',
          AddEditGoalStatus.loading,
        ),
        isA<AddEditGoalState>().having(
          (s) => s.status,
          'status',
          AddEditGoalStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => mockAddGoalUseCase(any())).called(1);
        verifyNever(() => mockUpdateGoalUseCase(any()));
      },
    );

    blocTest<AddEditGoalBloc, AddEditGoalState>(
      'emits [loading, error, initial] when SaveGoal fails (Add Mode)',
      setUp: () {
        when(
          () => mockAddGoalUseCase(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('DB Error')));
      },
      build: () => bloc,
      act: (bloc) =>
          bloc.add(const SaveGoal(name: 'New Car', targetAmount: 20000.0)),
      expect: () => [
        isA<AddEditGoalState>().having(
          (s) => s.status,
          'status',
          AddEditGoalStatus.loading,
        ),
        isA<AddEditGoalState>()
            .having((s) => s.status, 'status', AddEditGoalStatus.error)
            .having((s) => s.errorMessage, 'error', contains('Database Error')),
        isA<AddEditGoalState>().having(
          (s) => s.status,
          'status',
          AddEditGoalStatus.initial,
        ),
      ],
    );

    blocTest<AddEditGoalBloc, AddEditGoalState>(
      'emits [loading, success] when SaveGoal succeeds (Edit Mode)',
      setUp: () {
        when(
          () => mockUpdateGoalUseCase(any()),
        ).thenAnswer((_) async => Right(tGoal));
      },
      build: () => AddEditGoalBloc(
        addGoalUseCase: mockAddGoalUseCase,
        updateGoalUseCase: mockUpdateGoalUseCase,
        initialGoal: tGoal,
      ),
      act: (bloc) =>
          bloc.add(const SaveGoal(name: 'Updated Name', targetAmount: 25000.0)),
      expect: () => [
        isA<AddEditGoalState>().having(
          (s) => s.status,
          'status',
          AddEditGoalStatus.loading,
        ),
        isA<AddEditGoalState>().having(
          (s) => s.status,
          'status',
          AddEditGoalStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateGoalUseCase(any())).called(1);
        verifyNever(() => mockAddGoalUseCase(any()));
      },
    );

    blocTest<AddEditGoalBloc, AddEditGoalState>(
      'clears error message when ClearGoalFormMessage is added',
      build: () => bloc,
      seed: () => const AddEditGoalState(
        status: AddEditGoalStatus.error,
        errorMessage: 'Some error',
      ),
      act: (bloc) => bloc.add(const ClearGoalFormMessage()),
      expect: () => [
        isA<AddEditGoalState>()
            .having((s) => s.status, 'status', AddEditGoalStatus.initial)
            .having((s) => s.errorMessage, 'error', isNull)
            .having((s) => s.clearError, 'clearError', true),
      ],
    );
  });
}
