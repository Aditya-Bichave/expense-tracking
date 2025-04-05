// lib/features/goals/presentation/pages/add_edit_goal_page.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_form.dart'; // Create this next
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddEditGoalPage extends StatelessWidget {
  final Goal? initialGoal; // Passed via GoRouter extra

  const AddEditGoalPage({super.key, this.initialGoal});

  @override
  Widget build(BuildContext context) {
    final bool isEditing = initialGoal != null;
    log.info(
        "[AddEditGoalPage] Building. Editing: $isEditing. Goal: ${initialGoal?.name}");

    return BlocProvider<AddEditGoalBloc>(
      create: (_) => sl<AddEditGoalBloc>(param1: initialGoal),
      child: BlocListener<AddEditGoalBloc, AddEditGoalState>(
        listener: (context, state) {
          if (state.status == AddEditGoalStatus.success) {
            log.info("[AddEditGoalPage] Save successful. Popping.");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(
                    'Goal ${isEditing ? 'updated' : 'added'} successfully!'),
                backgroundColor: Colors.green,
              ));
            if (context.canPop()) context.pop();
          } else if (state.status == AddEditGoalStatus.error &&
              state.errorMessage != null) {
            log.warning("[AddEditGoalPage] Save error: ${state.errorMessage}");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('Error: ${state.errorMessage}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ));
            context.read<AddEditGoalBloc>().add(const ClearGoalFormMessage());
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Goal' : 'Add Goal'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () => context.pop(), // Close screen
            ),
          ),
          body: BlocBuilder<AddEditGoalBloc, AddEditGoalState>(
            builder: (context, state) {
              if (state.status == AddEditGoalStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              // Show form once initial state is processed
              return GoalForm(
                key: ValueKey(initialGoal?.id ?? 'new_goal'),
                initialGoal: state.initialGoal,
                onSubmit:
                    (name, targetAmount, targetDate, iconName, description) {
                  context.read<AddEditGoalBloc>().add(SaveGoal(
                        name: name,
                        targetAmount: targetAmount,
                        targetDate: targetDate,
                        iconName: iconName,
                        description: description,
                      ));
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
