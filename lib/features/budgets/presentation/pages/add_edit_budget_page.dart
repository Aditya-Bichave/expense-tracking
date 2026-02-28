// lib/features/budgets/presentation/pages/add_edit_budget_page.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/widgets/budget_form.dart'; // Create this next
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';

class AddEditBudgetPage extends StatelessWidget {
  final Budget? initialBudget; // Passed via GoRouter extra

  const AddEditBudgetPage({super.key, this.initialBudget});

  @override
  Widget build(BuildContext context) {
    final bool isEditing = initialBudget != null;
    log.info(
      "[AddEditBudgetPage] Building. Editing: $isEditing. Budget: ${initialBudget?.name}",
    );

    return BlocProvider<AddEditBudgetBloc>(
      // Use sl<>() to get the factory
      create: (_) => sl<AddEditBudgetBloc>(param1: initialBudget),
      child: BlocListener<AddEditBudgetBloc, AddEditBudgetState>(
        listener: (context, state) {
          if (state.status == AddEditBudgetStatus.success) {
            log.info("[AddEditBudgetPage] Save successful. Popping.");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'Budget ${isEditing ? 'updated' : 'added'} successfully!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            // Use context.pop() which is safer with GoRouter shells
            if (context.canPop()) context.pop();
          } else if (state.status == AddEditBudgetStatus.error &&
              state.errorMessage != null) {
            log.warning(
              "[AddEditBudgetPage] Save error: ${state.errorMessage}",
            );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.errorMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            // Clear error after showing
            context.read<AddEditBudgetBloc>().add(
              const ClearBudgetFormMessage(),
            );
          }
        },
        child: BridgeScaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Budget' : 'Add Budget'),
            leading: IconButton(
              key: const ValueKey('button_close'),
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () => context.pop(), // Close screen
            ),
          ),
          body: BlocBuilder<AddEditBudgetBloc, AddEditBudgetState>(
            builder: (context, state) {
              if (state.status == AddEditBudgetStatus.loading &&
                  state.availableCategories.isEmpty) {
                // Show loading only if categories aren't loaded yet for the form
                return const Center(child: BridgeCircularProgressIndicator());
              }
              if (state.status == AddEditBudgetStatus.error &&
                  state.availableCategories.isEmpty) {
                // Show error if categories failed to load
                return Center(
                  child: Text(
                    "Error loading form data: ${state.errorMessage ?? ''}",
                  ),
                );
              }

              // Show form once categories are available or if editing
              return BudgetForm(
                key: ValueKey(
                  initialBudget?.id ?? 'new',
                ), // Key for state preservation
                initialBudget: state.initialBudget,
                availableCategories:
                    state.availableCategories, // Pass categories
                onSubmit:
                    (name, type, amount, period, start, end, catIds, notes) {
                      context.read<AddEditBudgetBloc>().add(
                        SaveBudget(
                          name: name,
                          type: type,
                          targetAmount: amount,
                          period: period,
                          startDate: start,
                          endDate: end,
                          categoryIds: catIds,
                          notes: notes,
                        ),
                      );
                    },
              );
            },
          ),
        ),
      ),
    );
  }
}
