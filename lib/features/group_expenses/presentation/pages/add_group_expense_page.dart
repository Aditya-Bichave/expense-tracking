import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:expense_tracker/core/widgets/category_selector_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';

import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/ui_bridge/bridge_elevated_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AddGroupExpensePage extends StatefulWidget {
  final String groupId;
  final String groupCurrency;

  const AddGroupExpensePage({
    super.key,
    required this.groupId,
    required this.groupCurrency,
  });

  @override
  State<AddGroupExpensePage> createState() => _AddGroupExpensePageState();
}

class _AddGroupExpensePageState extends State<AddGroupExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  final _uuid = const Uuid();
  Category? _selectedCategory;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BridgeScaffold(
      appBar: AppBar(title: Text('Add Group Expense')),
      body: Padding(
        padding: context.space.allLg,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                key: const Key('group_expense_title_field'),
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                key: const Key('group_expense_amount_field'),
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<CategoryManagementBloc, CategoryManagementState>(
                builder: (context, catState) {
                  final categories =
                      catState.status == CategoryManagementStatus.loaded
                      ? catState.allExpenseCategories
                      : <Category>[];
                  return CategorySelectorTile(
                    selectedCategory: _selectedCategory,
                    uncategorizedCategory: Category.uncategorized,
                    onTap: () async {
                      final category = await showModalBottomSheet<Category?>(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => CategoryPickerDialogContent(
                          categoryType: CategoryTypeFilter.expense,
                          categories: categories,
                        ),
                      );
                      if (category != null && mounted) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              BridgeElevatedButton(
                onPressed: _submit,
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add a group expense.'),
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    final expense = GroupExpense(
      id: _uuid.v4(),
      groupId: widget.groupId,
      createdBy: authState.user.id,
      title: title,
      amount: amount,
      currency: widget.groupCurrency,
      occurredAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      categoryId: _selectedCategory?.id,
      payers: [ExpensePayer(userId: authState.user.id, amount: amount)],
      splits: [],
    );

    context.read<GroupExpensesBloc>().add(AddGroupExpenseRequested(expense));
    Navigator.pop(context);
  }
}
