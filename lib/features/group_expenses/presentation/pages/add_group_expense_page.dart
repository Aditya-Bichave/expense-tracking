import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/ui_bridge/bridge_elevated_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AddGroupExpensePage extends StatefulWidget {
  final String groupId;

  const AddGroupExpensePage({super.key, required this.groupId});

  @override
  State<AddGroupExpensePage> createState() => _AddGroupExpensePageState();
}

class _AddGroupExpensePageState extends State<AddGroupExpensePage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return BridgeScaffold(
      appBar: AppBar(title: const Text('Add Group Expense')),
      body: Padding(
        padding: const context.space.allLg,
        child: Column(
          children: [
            TextField(
              key: const Key('group_expense_title_field'),
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              key: const Key('group_expense_amount_field'),
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            BridgeElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final amount =
                    double.tryParse(_amountController.text.trim()) ?? 0;

                if (title.isNotEmpty && amount > 0) {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    final expense = GroupExpense(
                      id: _uuid.v4(),
                      groupId: widget.groupId,
                      createdBy: authState.user.id,
                      title: title,
                      amount: amount,
                      currency: 'USD',
                      occurredAt: DateTime.now(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      payers: [
                        ExpensePayer(userId: authState.user.id, amount: amount),
                      ],
                      splits: [],
                    );

                    context.read<GroupExpensesBloc>().add(
                      AddGroupExpenseRequested(expense),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
