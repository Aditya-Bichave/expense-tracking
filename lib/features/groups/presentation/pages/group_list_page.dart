import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/pages/create_group_page.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/core/di/service_locator.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  late final Stream<SyncServiceStatus> _syncStatusStream;

  @override
  void initState() {
    super.initState();
    context.read<GroupsBloc>().add(LoadGroups());
    _syncStatusStream = sl<SyncService>().statusStream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          StreamBuilder<SyncServiceStatus>(
            stream: _syncStatusStream,
            initialData: SyncServiceStatus.synced,
            builder: (context, snapshot) {
              final status = snapshot.hasError
                  ? SyncServiceStatus.error
                  : (snapshot.data ?? SyncServiceStatus.synced);
              IconData icon;
              Color? color;
              switch (status) {
                case SyncServiceStatus.synced:
                  icon = Icons.cloud_done;
                  color = Colors.green;
                  break;
                case SyncServiceStatus.syncing:
                  icon = Icons.cloud_upload;
                  color = Colors.blue;
                  break;
                case SyncServiceStatus.offline:
                  icon = Icons.cloud_off;
                  color = Colors.grey;
                  break;
                case SyncServiceStatus.error:
                  icon = Icons.error_outline;
                  color = Colors.red;
                  break;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(icon, color: color),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateGroupPage()));
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, state) {
          if (state is GroupsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GroupsLoaded) {
            if (state.groups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No groups yet.'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateGroupPage(),
                          ),
                        );
                      },
                      child: const Text('Create one'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.groups.length,
              itemBuilder: (context, index) {
                final group = state.groups[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(_getIconForType(group.type)),
                  ),
                  title: Text(group.name),
                  subtitle: Text(group.type.value.toUpperCase()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/groups/${group.id}');
                  },
                );
              },
            );
          } else if (state is GroupsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  IconData _getIconForType(GroupType type) {
    switch (type) {
      case GroupType.trip:
        return Icons.flight;
      case GroupType.couple:
        return Icons.favorite;
      case GroupType.home:
        return Icons.home;
      case GroupType.custom:
        return Icons.layers;
    }
  }
}
