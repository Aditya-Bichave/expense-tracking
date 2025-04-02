import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
// --- Import IncomeCategory and PredefinedIncomeCategory ---
import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
import 'package:expense_tracker/features/income/presentation/bloc/add_edit_income/add_edit_income_bloc.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_form.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart'; // For FormStatus

class AddEditIncomePage extends StatelessWidget {
  final String? incomeId;
  final Income? income;

  const AddEditIncomePage({
    super.key,
    this.incomeId,
    this.income,
  });

  // --- Helper to find IncomeCategory object from ID (assuming ID is the name) ---
  // Adjust if your IDs are different or you have custom categories
  IncomeCategory _findIncomeCategoryById(String categoryId) {
    try {
      // Find the predefined enum value matching the ID (which is likely the name from the form)
      final predefined = PredefinedIncomeCategory.values.firstWhere((e) =>
              IncomeCategory.fromPredefined(e).name.toLowerCase() ==
              categoryId.toLowerCase()
          // Or if your IncomeCategory ID is different: (e) => IncomeCategory.fromPredefined(e).id == categoryId
          );
      // Reconstruct the IncomeCategory object using the factory
      return IncomeCategory.fromPredefined(predefined);
    } catch (e) {
      // Fallback if not found (shouldn't happen if dropdown is populated correctly)
      debugPrint(
          "Warning: Could not find IncomeCategory for ID '$categoryId'. Defaulting.");
      // Return a default category or handle error appropriately
      return IncomeCategory.fromPredefined(
          PredefinedIncomeCategory.other); // Example default
    }
  }
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isEditing = income != null;

    return BlocProvider(
      create: (context) => sl<AddEditIncomeBloc>(param1: income),
      child: BlocListener<AddEditIncomeBloc, AddEditIncomeState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            try {
              sl<IncomeListBloc>().add(LoadIncomes());
            } catch (e) {
              debugPrint("Could not refresh income list: $e");
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Income ${isEditing ? 'updated' : 'added'} successfully!')),
            );
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
            title: Text(isEditing ? 'Edit Income' : 'Add Income'),
          ),
          body: BlocBuilder<AddEditIncomeBloc, AddEditIncomeState>(
            builder: (context, state) {
              if (state.status == FormStatus.submitting) {
                return const Center(child: CircularProgressIndicator());
              }

              return IncomeForm(
                initialIncome: state.initialIncome ?? income,
                // onSubmit provides categoryId as a String
                onSubmit: (title, amount, categoryId, accountId, date, notes) {
                  // --- Convert categoryId string to IncomeCategory object ---
                  final IncomeCategory categoryObject =
                      _findIncomeCategoryById(categoryId);
                  // --------------------------------------------------------

                  final bloc = context.read<AddEditIncomeBloc>();

                  // Dispatch the SaveIncomeRequested event
                  bloc.add(SaveIncomeRequested(
                    existingIncomeId: isEditing ? income!.id : null,
                    title: title,
                    amount: amount,
                    // --- Pass the IncomeCategory OBJECT ---
                    category: categoryObject,
                    // ------------------------------------
                    accountId: accountId,
                    date: date,
                    notes: notes,
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
