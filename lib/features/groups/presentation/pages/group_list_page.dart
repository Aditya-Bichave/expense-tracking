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
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_fab.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';

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
    final kit = context.kit;

    return AppScaffold(
      appBar: AppNavBar(
        title: 'Groups',
        actions: [
          StreamBuilder<SyncServiceStatus>(
            stream: _syncStatusStream,
            initialData: SyncServiceStatus.synced,
            builder: (context, snapshot) {
              final status = snapshot.data ?? SyncServiceStatus.synced;
              IconData icon;
              Color? color;
              switch (status) {
                case SyncServiceStatus.synced:
                  icon = Icons.cloud_done;
                  color = kit.colors.success;
                  break;
                case SyncServiceStatus.syncing:
                  icon = Icons.cloud_upload;
                  color = kit.colors.primary;
                  break;
                case SyncServiceStatus.offline:
                  icon = Icons.cloud_off;
                  color = kit.colors.textSecondary;
                  break;
                case SyncServiceStatus.error:
                  icon = Icons.error_outline;
                  color = kit.colors.error;
                  break;
              }
              return Padding(
                padding: kit.spacing.hMd,
                child: Icon(icon, color: color),
              );
            },
          ),
        ],
      ),
      floatingActionButton: AppFAB(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateGroupPage()));
        },
        icon: const Icon(Icons.add),
      ),
      body: BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, state) {
          if (state is GroupsLoading) {
            return const AppLoadingIndicator();
          } else if (state is GroupsLoaded) {
            if (state.groups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_off,
                      size: 64,
                      color: kit.colors.textSecondary,
                    ),
                    kit.spacing.gapLg,
                    Text('No groups yet.', style: kit.typography.body),
                    AppButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateGroupPage(),
                          ),
                        );
                      },
                      label: 'Create one',
                      variant: AppButtonVariant.ghost,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.groups.length,
              itemBuilder: (context, index) {
                final group = state.groups[index];
                return AppListTile(
                  leading: AppAvatar(
                    initials: _getIconForType(group.type).toString(),
                    backgroundColor: kit.colors.primaryContainer,
                    foregroundColor: kit.colors.onPrimaryContainer,
                  ),
                  title: Text(group.name),
                  subtitle: Text(group.type.value.toUpperCase()),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: kit.colors.textSecondary,
                  ),
                  onTap: () {
                    context.push('/groups/${group.id}');
                  },
                );
              },
            );
          } else if (state is GroupsError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: kit.typography.body.copyWith(color: kit.colors.error),
              ),
            );
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
