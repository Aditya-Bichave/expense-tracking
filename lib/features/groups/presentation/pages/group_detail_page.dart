import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/group_expenses/presentation/pages/add_group_expense_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:get_it/get_it.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          GroupExpensesBloc(GetIt.I<GroupExpensesRepository>())
            ..add(LoadGroupExpenses(widget.groupId)),
      child: Builder(
        builder: (context) {
          final groupsState = context.watch<GroupsBloc>().state;
          String groupName = 'Group';
          if (groupsState is GroupsLoaded) {
            try {
              final group = groupsState.groups.firstWhere(
                (g) => g.id == widget.groupId,
              );
              groupName = group.name;
            } catch (_) {}
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(groupName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _generateInvite(context),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<GroupExpensesBloc>(),
                      child: AddGroupExpensePage(groupId: widget.groupId),
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
            body: BlocBuilder<GroupExpensesBloc, GroupExpensesState>(
              builder: (context, state) {
                if (state is GroupExpensesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is GroupExpensesLoaded) {
                  if (state.expenses.isEmpty) {
                    return const Center(child: Text('No expenses yet.'));
                  }
                  return ListView.builder(
                    itemCount: state.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = state.expenses[index];
                      return ListTile(
                        title: Text(expense.title),
                        trailing: Text('${expense.amount} ${expense.currency}'),
                        subtitle: Text('Paid by ${expense.createdBy}'),
                      );
                    },
                  );
                } else if (state is GroupExpensesError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateInvite(BuildContext context) async {
    try {
      final repo = GetIt.I<GroupsRepository>();
      final result = await repo.createInvite(widget.groupId);
      result.fold(
        (failure) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message))),
        (token) {
          final link = 'expenses://invite?token=$token';
          Clipboard.setData(ClipboardData(text: link));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite link copied to clipboard')),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
