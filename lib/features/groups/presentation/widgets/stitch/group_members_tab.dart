import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_icon_button.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';

class GroupMembersTab extends StatelessWidget {
  const GroupMembersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return BlocBuilder<GroupMembersBloc, GroupMembersState>(
      builder: (context, state) {
        if (state is GroupMembersLoading) {
          return const AppLoadingIndicator();
        } else if (state is GroupMembersLoaded) {
          final currentUser =
              (context.read<AuthBloc>().state as AuthAuthenticated).user;
          final currentMember = state.members.firstWhere(
            (m) => m.userId == currentUser.id,
            orElse: () => state.members.first, // Fallback
          );
          final isAdmin = currentMember.role == GroupRole.admin;

          return ListView.builder(
            itemCount: state.members.length,
            itemBuilder: (context, index) {
              final member = state.members[index];
              final isMe = member.userId == currentUser.id;

              return AppListTile(
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
                        onPressed: () => _showMemberOptions(
                          context,
                          member.groupId,
                          member.userId,
                          member.role.name,
                        ),
                      )
                    : null,
              );
            },
          );
        } else if (state is GroupMembersError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: kit.typography.body.copyWith(color: kit.colors.error),
            ),
          );
        }
        return Center(
          child: Text('No members loaded', style: kit.typography.body),
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

    showModalBottomSheet(
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

  void _confirmKickMember(BuildContext context, String groupId, String userId) {
    AppDialog.show(
      context: context,
      title: 'Remove Member?',
      content:
          'Are you sure you want to remove this member? This action cannot be undone.',
      isDestructive: true,
      confirmLabel: 'Remove',
      cancelLabel: 'Cancel',
      onConfirm: () {
        context.read<GroupMembersBloc>().add(
          KickMember(groupId: groupId, userId: userId),
        );
        Navigator.pop(context);
      },
    );
  }
}
