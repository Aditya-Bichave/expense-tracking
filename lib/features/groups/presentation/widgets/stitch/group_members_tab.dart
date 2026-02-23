import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';

class GroupMembersTab extends StatelessWidget {
  const GroupMembersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupMembersBloc, GroupMembersState>(
      builder: (context, state) {
        if (state is GroupMembersLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GroupMembersLoaded) {
          final currentUser =
              (context.read<AuthBloc>().state as AuthAuthenticated).user;
          final currentMember = state.members.firstWhere(
            (m) => m.userId == currentUser.id,
            orElse: () => state.members.first, // Fallback, though unlikely
          );
          final isAdmin = currentMember.role == GroupRole.admin;

          return ListView.builder(
            itemCount: state.members.length,
            itemBuilder: (context, index) {
              final member = state.members[index];
              final isMe = member.userId == currentUser.id;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(member.userId.substring(0, 2).toUpperCase()),
                ),
                title: Text('${member.role.name} ${isMe ? '(You)' : ''}'),
                subtitle: Text(member.userId), // Or display name if available
                trailing: (isAdmin && !isMe)
                    ? IconButton(
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
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('No members loaded'));
      },
    );
  }

  void _showMemberOptions(
    BuildContext context,
    String groupId,
    String userId,
    String currentRole,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Change Role'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeRoleDialog(context, groupId, userId, currentRole);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text(
                  'Remove Member',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmKickMember(context, groupId, userId);
                },
              ),
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
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Role'),
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
                  if (role == currentRole) const Icon(Icons.check, size: 16),
                  const SizedBox(width: 8),
                  Text(role.toUpperCase()),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _confirmKickMember(BuildContext context, String groupId, String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Member?'),
          content: const Text(
            'Are you sure you want to remove this member? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<GroupMembersBloc>().add(
                  KickMember(groupId: groupId, userId: userId),
                );
                Navigator.pop(context);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
