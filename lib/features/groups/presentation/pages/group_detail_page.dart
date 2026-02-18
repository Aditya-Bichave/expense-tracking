import 'package:expense_tracker/features/groups/presentation/bloc/group_detail_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_expense_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;
  final GroupEntity? initialGroup;

  const GroupDetailPage({super.key, required this.groupId, this.initialGroup});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupDetailBloc, GroupDetailState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is GroupDetailLoading && initialGroup == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        GroupEntity? group;
        if (state is GroupDetailLoaded) {
          group = state.group;
        } else {
          group = initialGroup;
        }

        if (group == null) {
          return const Scaffold(body: Center(child: Text("Group not found")));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share(
                    'Join my group ${group!.name}: https://yourapp.com/join/${group.id}',
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (state is GroupDetailLoaded) ...[
                // Members Summary
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      const Icon(Icons.people),
                      const SizedBox(width: 8),
                      Text('${state.members.length} Members'),
                      const Spacer(),
                    ],
                  ),
                ),
                // Expenses List
                Expanded(
                  child: ListView.builder(
                    itemCount: state.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = state.expenses[index];
                      return ListTile(
                        title: Text(expense.title),
                        subtitle: Text('${expense.amount} ${expense.currency}'),
                        trailing: Text(
                          expense.occurredAt.toString().split(' ')[0],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showAddExpenseDialog(context, group!.id);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, String groupId) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Group Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final title = titleController.text.trim();
                final amount = double.tryParse(amountController.text.trim());
                if (title.isNotEmpty && amount != null) {
                  final expense = GroupExpenseEntity(
                    id: '',
                    groupId: groupId,
                    title: title,
                    amount: amount,
                    currency: 'USD',
                    occurredAt: DateTime.now(),
                    createdBy: '',
                  );
                  context.read<GroupDetailBloc>().add(AddExpense(expense));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
