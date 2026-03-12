import 'package:collection/collection.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_state.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/ui_bridge/bridge_bottom_sheet.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_icon_button.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupMembersTab extends StatelessWidget {
  final String groupId;

  const GroupMembersTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return BlocBuilder<GroupMembersBloc, GroupMembersState>(
      builder: (context, state) {
        if (state.isInitialLoadInProgress) {
          return const AppLoadingIndicator();
        }

        if (state.hasBlockingError) {
          return Center(
            child: Padding(
              padding: kit.spacing.allLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error: ${state.message ?? 'Failed to load members'}',
                    textAlign: TextAlign.center,
                    style: kit.typography.body.copyWith(
                      color: kit.colors.error,
                    ),
                  ),
                  kit.spacing.gapLg,
                  ElevatedButton(
                    onPressed: () {
                      context.read<GroupMembersBloc>().add(
                        LoadGroupMembers(groupId),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.members.isEmpty) {
          return Center(
            child: Text('No members loaded', style: kit.typography.body),
          );
        }

        final authState = context.read<AuthBloc>().state;
        if (authState is! AuthAuthenticated) {
          return Center(
            child: Text(
              'Please log in to view members.',
              style: kit.typography.body,
            ),
          );
        }

        final currentUser = authState.user;
        final currentMember = state.members
            .where((member) => member.userId == currentUser.id)
            .firstOrNull;
        final isAdmin = currentMember?.role == GroupRole.admin;

        return Column(
          children: [
            if (state.isBusy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView.builder(
                itemCount: state.members.length,
                itemBuilder: (context, index) {
                  final member = state.members[index];
                  final isMe = member.userId == currentUser.id;

                  return AppListTile(
                    key: ValueKey('tile_groupMember_${member.userId}'),
                    leading: AppAvatar(
                      initials: member.userId.substring(0, 2).toUpperCase(),
                      backgroundColor: kit.colors.primaryContainer,
                      foregroundColor: kit.colors.onPrimaryContainer,
                    ),
                    title: Text('${member.role.name} ${isMe ? '(You)' : ''}'),
                    subtitle: Text(member.userId),
                    trailing: (isAdmin && !isMe)
                        ? AppIconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: state.isBusy
                                ? null
                                : () => _showMemberOptions(
                                    context,
                                    member.groupId,
                                    member.userId,
                                    member.role.name,
                                  ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMemberOptions(
    BuildContext context,
    String groupId,
    String userId,
    String currentRole,
  ) {
    final kit = context.kit;

    bridgeShowModalBottomSheet(
      context: context,
      backgroundColor: kit.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: kit.radii.sheet),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              kit.spacing.gapSm,
              AppListTile(
                leading: Icon(Icons.security, color: kit.colors.textPrimary),
                title: const Text('Change Role'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeRoleDialog(context, groupId, userId, currentRole);
                },
              ),
              AppListTile(
                leading: Icon(Icons.person_remove, color: kit.colors.error),
                title: Text(
                  'Remove Member',
                  style: kit.typography.body.copyWith(color: kit.colors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmKickMember(context, groupId, userId);
                },
              ),
              kit.spacing.gapSm,
            ],
          ),
        );
      },
    );
  }

  void _showChangeRoleDialog(
    BuildContext context,
    String groupId,
    String userId,
    String currentRole,
  ) {
    final kit = context.kit;

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: kit.colors.surface,
          title: Text('Select Role', style: kit.typography.headline),
          children: ['admin', 'member', 'viewer'].map((role) {
            return SimpleDialogOption(
              onPressed: () {
                context.read<GroupMembersBloc>().add(
                  ChangeMemberRole(
                    groupId: groupId,
                    userId: userId,
                    newRole: role,
                  ),
                );
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  if (role == currentRole)
                    Icon(Icons.check, size: 16, color: kit.colors.primary),
                  kit.spacing.gapSm,
                  Text(role.toUpperCase(), style: kit.typography.body),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _confirmKickMember(
    BuildContext context,
    String groupId,
    String userId,
  ) async {
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: 'Remove Member?',
      content:
          'Are you sure you want to remove this member? This action cannot be undone.',
      confirmText: 'Remove',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed != true) {
      return;
    }
    context.read<GroupMembersBloc>().add(
      KickMember(groupId: groupId, userId: userId),
    );
  }
}
