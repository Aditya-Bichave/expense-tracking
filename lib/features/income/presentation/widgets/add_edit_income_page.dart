import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
import 'package:expense_tracker/features/income/presentation/bloc/add_edit_income/add_edit_income_bloc.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_form.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart'; // For FormStatus
// Removed explicit Bloc imports for refresh

class AddEditIncomePage extends StatelessWidget {
  final String? incomeId;
  final Income? income;

  const AddEditIncomePage({
    super.key,
    this.incomeId,
    this.income,
  });

  IncomeCategory _findIncomeCategoryById(String categoryId) {
    try {
      final predefined = PredefinedIncomeCategory.values.firstWhere((e) =>
          IncomeCategory.fromPredefined(e).name.toLowerCase() ==
          categoryId.toLowerCase());
      return IncomeCategory.fromPredefined(predefined);
    } catch (e) {
      debugPrint(
          "Warning: Could not find IncomeCategory for ID '$categoryId'. Defaulting.");
      return IncomeCategory.fromPredefined(PredefinedIncomeCategory.other);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = income != null;

    return BlocProvider(
      create: (context) => sl<AddEditIncomeBloc>(param1: income),
      child: BlocListener<AddEditIncomeBloc, AddEditIncomeState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            // No explicit refreshes needed here
            debugPrint(
                "Income save successful, relying on stream for refresh.");

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
                onSubmit: (title, amount, categoryId, accountId, date, notes) {
                  final IncomeCategory categoryObject =
                      _findIncomeCategoryById(categoryId);
                  final bloc = context.read<AddEditIncomeBloc>();
                  bloc.add(SaveIncomeRequested(
                    existingIncomeId: isEditing ? income!.id : null,
                    title: title,
                    amount: amount,
                    category: categoryObject,
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
