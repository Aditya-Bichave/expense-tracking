import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';

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

  bool _isSplitMode = false;
  final List<ExpenseSplit> _splits = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Group Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Split Expense'),
              subtitle: const Text('Enable exact split'),
              value: _isSplitMode,
              onChanged: (val) {
                setState(() {
                  _isSplitMode = val;
                  if (!_isSplitMode) _splits.clear();
                });
              },
            ),

            if (_isSplitMode) ...[
              const SizedBox(height: 8),
              const Text("Splits", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  final userId = authState is AuthAuthenticated ? authState.user.id : 'unknown';
                  // Allow adding multiple splits for demo/testing validation
                  setState(() {
                    _splits.add(ExpenseSplit(
                      userId: '${userId}_${_splits.length}', // Unique-ish ID fixed interpolation
                      amount: 0,
                      splitType: SplitType.exact,
                    ));
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Split Participant"),
              ),
              const SizedBox(height: 8),
              ..._splits.asMap().entries.map((entry) {
                final index = entry.key;
                final split = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text("Participant ${index + 1}"),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Amount",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final newAmount = double.tryParse(val) ?? 0;
                            setState(() {
                              _splits[index] = ExpenseSplit(
                                userId: split.userId,
                                amount: newAmount,
                                splitType: SplitType.exact,
                              );
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _splits.removeAt(index);
                          });
                        },
                      )
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final amount =
                    double.tryParse(_amountController.text.trim()) ?? 0;

                if (title.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid title and amount')),
                  );
                  return;
                }

                // --- VALIDATION LOGIC (ADI-31) ---
                if (_isSplitMode && _splits.isNotEmpty) {
                  final totalSplits = _splits.fold(0.0, (sum, s) => sum + s.amount);
                  // Allow 0.01 tolerance for floating point math
                  if ((totalSplits - amount).abs() > 0.01) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Splits sum ($totalSplits) does not match total amount ($amount). Difference: ${(amount - totalSplits).toStringAsFixed(2)}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return; // Stop save
                  }
                }
                // ---------------------------------

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
                    splits: _isSplitMode ? _splits : [],
                  );

                  context.read<GroupExpensesBloc>().add(
                    AddGroupExpenseRequested(expense),
                  );
                  Navigator.pop(context);
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
