import 'package:expense_tracker/features/groups/presentation/bloc/group_list_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GroupListBloc>().add(RefreshGroups());
            },
          ),
        ],
      ),
      body: BlocBuilder<GroupListBloc, GroupListState>(
        builder: (context, state) {
          if (state is GroupListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GroupListLoaded) {
            final groups = state.groups;
            if (groups.isEmpty) {
              return const Center(child: Text('No groups yet. Create one!'));
            }
            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  title: Text(group.name),
                  subtitle: Text('Members: ${group.memberCount}'),
                  onTap: () {
                    context.push('/groups/${group.id}', extra: group);
                  },
                );
              },
            );
          } else if (state is GroupListError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateGroupDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Group'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Group Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<GroupListBloc>().add(CreateGroup(name));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
