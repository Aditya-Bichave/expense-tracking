import 'package:equatable/equatable.dart';

abstract class GroupMembersEvent extends Equatable {
  const GroupMembersEvent();

  @override
  List<Object?> get props => [];
}

class LoadGroupMembers extends GroupMembersEvent {
  final String groupId;

  const LoadGroupMembers(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class GenerateInviteLink extends GroupMembersEvent {
  final String groupId;
  final String role;
  final int expiryDays;
  final int maxUses;

  const GenerateInviteLink({
    required this.groupId,
    this.role = 'member',
    this.expiryDays = 7,
    this.maxUses = 0,
  });

  @override
  List<Object?> get props => [groupId, role, expiryDays, maxUses];
}

class ChangeMemberRole extends GroupMembersEvent {
  final String groupId;
  final String userId;
  final String newRole;

  const ChangeMemberRole({
    required this.groupId,
    required this.userId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [groupId, userId, newRole];
}

class KickMember extends GroupMembersEvent {
  final String groupId;
  final String userId;

  const KickMember({required this.groupId, required this.userId});

  @override
  List<Object?> get props => [groupId, userId];
}

class LeaveCurrentGroup extends GroupMembersEvent {
  final String groupId;
  final String userId;

  const LeaveCurrentGroup({required this.groupId, required this.userId});

  @override
  List<Object?> get props => [groupId, userId];
}

class DeleteCurrentGroup extends GroupMembersEvent {
  final String groupId;

  const DeleteCurrentGroup({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}
