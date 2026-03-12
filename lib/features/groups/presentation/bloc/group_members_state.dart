import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';

enum GroupMembersStatus { initial, loading, loaded, error }

enum GroupMembersAction {
  none,
  generatingInvite,
  inviteGenerated,
  updatingRole,
  memberRoleUpdated,
  removingMember,
  memberRemoved,
  leavingGroup,
  leftGroup,
  deletingGroup,
  deletedGroup,
  failed,
}

class GroupMembersState extends Equatable {
  final GroupMembersStatus status;
  final GroupMembersAction action;
  final List<GroupMember> members;
  final String? groupId;
  final String? message;
  final String? inviteUrl;

  const GroupMembersState({
    required this.status,
    required this.action,
    required this.members,
    this.groupId,
    this.message,
    this.inviteUrl,
  });

  factory GroupMembersState.initial() {
    return const GroupMembersState(
      status: GroupMembersStatus.initial,
      action: GroupMembersAction.none,
      members: <GroupMember>[],
    );
  }

  bool get isInitialLoadInProgress =>
      status == GroupMembersStatus.loading && members.isEmpty;

  bool get hasBlockingError =>
      status == GroupMembersStatus.error && members.isEmpty;

  bool get isBusy =>
      action == GroupMembersAction.generatingInvite ||
      action == GroupMembersAction.updatingRole ||
      action == GroupMembersAction.removingMember ||
      action == GroupMembersAction.leavingGroup ||
      action == GroupMembersAction.deletingGroup;

  GroupMembersState copyWith({
    GroupMembersStatus? status,
    GroupMembersAction? action,
    List<GroupMember>? members,
    String? groupId,
    String? message,
    String? inviteUrl,
    bool clearMessage = false,
    bool clearInviteUrl = false,
  }) {
    return GroupMembersState(
      status: status ?? this.status,
      action: action ?? this.action,
      members: members ?? this.members,
      groupId: groupId ?? this.groupId,
      message: clearMessage ? null : (message ?? this.message),
      inviteUrl: clearInviteUrl ? null : (inviteUrl ?? this.inviteUrl),
    );
  }

  @override
  List<Object?> get props => [
    status,
    action,
    members,
    groupId,
    message,
    inviteUrl,
  ];
}
