import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAddGoalUseCase extends Mock implements AddGoalUseCase {}

class MockUpdateGoalUseCase extends Mock implements UpdateGoalUseCase {}

void main() {
  group('AddEditGoalBloc', () {
    late MockAddGoalUseCase addGoal;
    late MockUpdateGoalUseCase updateGoal;

    setUp(() {
      addGoal = MockAddGoalUseCase();
      updateGoal = MockUpdateGoalUseCase();
    });

    test('initial state reflects provided goal without extra event', () {
      final goal = Goal(
        id: '1',
        name: 'g',
        targetAmount: 100,
        status: GoalStatus.active,
        totalSaved: 0,
        createdAt: DateTime(2024),
      );
      final bloc = AddEditGoalBloc(
        addGoalUseCase: addGoal,
        updateGoalUseCase: updateGoal,
        initialGoal: goal,
      );
      expect(bloc.state.initialGoal, goal);
    });
  });
}
