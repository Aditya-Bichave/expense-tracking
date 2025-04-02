import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_form.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';

class AddEditExpensePage extends StatelessWidget {
  final String? expenseId; // Passed from router for editing
  final Expense? expense; // Passed via router extra for editing

  const AddEditExpensePage({
    super.key,
    this.expenseId,
    this.expense,
  });

  // Helper to find Category object from ID (assuming ID is the name)
  Category _findCategoryById(String categoryId) {
    final predefined = PredefinedCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == categoryId.toLowerCase(),
      orElse: () => PredefinedCategory.other,
    );
    return Category.fromPredefined(predefined);
    // Note: This still doesn't handle subcategories if they were encoded differently.
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = expense != null;

    return BlocProvider(
      // Pass initial expense to BLoC if editing
      create: (context) => sl<AddEditExpenseBloc>(param1: expense),
      child: BlocListener<AddEditExpenseBloc, AddEditExpenseState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            try {
              // Refresh list upon successful save/update
              sl<ExpenseListBloc>().add(LoadExpenses());
            } catch (e) {
              // Log if ExpenseListBloc isn't ready, but don't crash
              debugPrint("Could not find ExpenseListBloc to refresh: $e");
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Expense ${isEditing ? 'updated' : 'added'} successfully!')),
            );
            // Navigate back if possible
            if (context.canPop()) {
              context.pop();
            }
          } else if (state.status == FormStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.errorMessage}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
          ),
          body: BlocBuilder<AddEditExpenseBloc, AddEditExpenseState>(
            builder: (context, state) {
              // Show loading indicator while submitting
              if (state.status == FormStatus.submitting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Display the form
              return ExpenseForm(
                initialExpense:
                    state.initialExpense, // Use state's initial expense
                // onSubmit receives data from the form, including accountId
                onSubmit: (title, amount, categoryId, accountId, date) {
                  // Convert categoryId string back to Category object
                  final Category categoryObject = _findCategoryById(categoryId);

                  // Dispatch the event to the BLoC
                  context.read<AddEditExpenseBloc>().add(
                        SaveExpenseRequested(
                          existingExpenseId: isEditing ? expense?.id : null,
                          title: title,
                          amount: amount,
                          category: categoryObject,
                          date: date,
                          // --- FIX: Pass the accountId from the form ---
                          accountId: accountId,
                          // ---------------------------------------------
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
