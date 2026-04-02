import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/pages/create_group_page.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_fab.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';

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
    _syncStatusStream = sl<SyncService>().statusStream;
  }

  void _navigateToCreateGroup(BuildContext context) {
    context.goNamed(RouteNames.groupCreate);
  }

  String _getInitialsForGroup(String name) {
    if (name.isEmpty) return 'G';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
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
              final status = snapshot.hasError
                  ? SyncServiceStatus.error
                  : (snapshot.data ?? SyncServiceStatus.synced);
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
        onPressed: () => _navigateToCreateGroup(context),
        icon: const Icon(Icons.add),
      ),
      body: BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, state) {
          if (state is GroupsLoading) {
            return const AppLoadingIndicator();
          } else if (state is GroupsLoaded) {
            if (state.groups.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  final bloc = context.read<GroupsBloc>();
                  bloc.add(const RefreshGroups(showLoading: true));
                  try {
                    await bloc.stream
                        .firstWhere(
                          (s) => s is GroupsLoaded || s is GroupsError,
                        )
                        .timeout(const Duration(seconds: 3));
                  } catch (_) {
                    // Prevent unhandled errors or timeouts
                  }
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                    Icon(
                      Icons.group_off,
                      size: 64,
                      color: kit.colors.textSecondary,
                    ),
                    kit.spacing.gapLg,
                    Center(
                      child: Text('No groups yet.', style: kit.typography.body),
                    ),
                    Center(
                      child: AppButton(
                        onPressed: () => _navigateToCreateGroup(context),
                        label: 'Create one',
                        variant: AppButtonVariant.ghost,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<GroupsBloc>();
                bloc.add(const RefreshGroups(showLoading: true));
                try {
                  await bloc.stream
                      .firstWhere((s) => s is GroupsLoaded || s is GroupsError)
                      .timeout(const Duration(seconds: 3));
                } catch (_) {
                  // Prevent unhandled errors or timeouts
                }
              },
              child: ListView.builder(
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return AppListTile(
                    key: ValueKey('tile_group_${group.id}'),
                    leading: AppAvatar(
                      initials: _getInitialsForGroup(group.name),
                      imageUrl: group.photoUrl,
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
                      context.go('${RouteNames.groups}/${group.id}');
                    },
                  );
                },
              ),
            );
          } else if (state is GroupsError) {
            return Center(
              child: Padding(
                padding: kit.spacing.allLg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: kit.typography.body.copyWith(
                        color: kit.colors.error,
                      ),
                    ),
                    kit.spacing.gapLg,
                    AppButton(
                      key: const ValueKey('button_groupList_retry'),
                      onPressed: () {
                        context.read<GroupsBloc>().add(
                          const RefreshGroups(showLoading: true),
                        );
                      },
                      label: 'Retry',
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
