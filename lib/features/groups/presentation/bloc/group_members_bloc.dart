import 'package:bloc/bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

import 'group_members_event.dart';
import 'group_members_state.dart';

class GroupMembersBloc extends Bloc<GroupMembersEvent, GroupMembersState> {
  final GroupsRepository _repository;

  GroupMembersBloc(this._repository) : super(GroupMembersState.initial()) {
    on<LoadGroupMembers>(_onLoadGroupMembers);
    on<GenerateInviteLink>(_onGenerateInviteLink);
    on<ChangeMemberRole>(_onChangeMemberRole);
    on<KickMember>(_onKickMember);
    on<LeaveCurrentGroup>(_onLeaveCurrentGroup);
    on<DeleteCurrentGroup>(_onDeleteCurrentGroup);
  }

  Future<void> _onLoadGroupMembers(
    LoadGroupMembers event,
    Emitter<GroupMembersState> emit,
  ) async {
    final previousMembers = state.groupId == event.groupId
        ? state.members
        : const <GroupMember>[];
    emit(
      state.copyWith(
        status: GroupMembersStatus.loading,
        groupId: event.groupId,
        members: previousMembers,
        action: GroupMembersAction.none,
        clearMessage: true,
        clearInviteUrl: true,
      ),
    );

    final result = await _repository.getGroupMembers(event.groupId);
    result.fold(
      (failure) {
        final nextStatus = previousMembers.isEmpty
            ? GroupMembersStatus.error
            : GroupMembersStatus.loaded;
        emit(
          state.copyWith(
            status: nextStatus,
            groupId: event.groupId,
            members: previousMembers,
            action: GroupMembersAction.failed,
            message: failure.message,
          ),
        );
      },
      (members) {
        emit(
          state.copyWith(
            status: GroupMembersStatus.loaded,
            groupId: event.groupId,
            members: members,
            action: GroupMembersAction.none,
            clearMessage: true,
            clearInviteUrl: true,
          ),
        );
      },
    );
  }

  Future<void> _onGenerateInviteLink(
    GenerateInviteLink event,
    Emitter<GroupMembersState> emit,
  ) async {
    emit(
      state.copyWith(
        action: GroupMembersAction.generatingInvite,
        clearMessage: true,
        clearInviteUrl: true,
      ),
    );

    final result = await _repository.createInvite(
      event.groupId,
      role: event.role,
      expiryDays: event.expiryDays,
      maxUses: event.maxUses,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          action: GroupMembersAction.failed,
          message: failure.message,
          clearInviteUrl: true,
        ),
      ),
      (url) => emit(
        state.copyWith(
          status: GroupMembersStatus.loaded,
          action: GroupMembersAction.inviteGenerated,
          inviteUrl: url,
          message: 'Invite link copied to clipboard',
        ),
      ),
    );
  }

  Future<void> _onChangeMemberRole(
    ChangeMemberRole event,
    Emitter<GroupMembersState> emit,
  ) async {
    emit(
      state.copyWith(
        action: GroupMembersAction.updatingRole,
        clearMessage: true,
        clearInviteUrl: true,
      ),
    );

    final result = await _repository.updateMemberRole(
      event.groupId,
      event.userId,
      event.newRole,
    );

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            action: GroupMembersAction.failed,
            message: failure.message,
          ),
        );
      },
      (_) async {
        await _reloadMembers(
          emit,
          groupId: event.groupId,
          successAction: GroupMembersAction.memberRoleUpdated,
          successMessage: 'Member role updated',
        );
      },
    );
  }

  Future<void> _onKickMember(
    KickMember event,
    Emitter<GroupMembersState> emit,
  ) async {
    emit(
      state.copyWith(
        action: GroupMembersAction.removingMember,
        clearMessage: true,
        clearInviteUrl: true,
      ),
    );

    final result = await _repository.removeMember(event.groupId, event.userId);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            action: GroupMembersAction.failed,
            message: failure.message,
          ),
        );
      },
      (_) async {
        await _reloadMembers(
          emit,
          groupId: event.groupId,
          successAction: GroupMembersAction.memberRemoved,
          successMessage: 'Member removed',
        );
      },
    );
  }

  Future<void> _onLeaveCurrentGroup(
    LeaveCurrentGroup event,
    Emitter<GroupMembersState> emit,
  ) async {
    emit(
      state.copyWith(
        action: GroupMembersAction.leavingGroup,
        clearMessage: true,
        clearInviteUrl: true,
      ),
    );

    final result = await _repository.leaveGroup(event.groupId, event.userId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          action: GroupMembersAction.failed,
          message: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          action: GroupMembersAction.leftGroup,
          message: 'You left the group',
        ),
      ),
    );
  }

  Future<void> _onDeleteCurrentGroup(
    DeleteCurrentGroup event,
    Emitter<GroupMembersState> emit,
  ) async {
    emit(
      state.copyWith(
        action: GroupMembersAction.deletingGroup,
        clearMessage: true,
        clearInviteUrl: true,
      ),
    );

    final result = await _repository.deleteGroup(event.groupId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          action: GroupMembersAction.failed,
          message: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          action: GroupMembersAction.deletedGroup,
          message: 'Group deleted',
        ),
      ),
    );
  }

  Future<void> _reloadMembers(
    Emitter<GroupMembersState> emit, {
    required String groupId,
    required GroupMembersAction successAction,
    required String successMessage,
  }) async {
    final membersResult = await _repository.getGroupMembers(groupId);
    membersResult.fold(
      (failure) => emit(
        state.copyWith(
          status: GroupMembersStatus.loaded,
          action: GroupMembersAction.failed,
          message: failure.message,
        ),
      ),
      (members) => emit(
        state.copyWith(
          status: GroupMembersStatus.loaded,
          groupId: groupId,
          members: members,
          action: successAction,
          message: successMessage,
          clearInviteUrl: true,
        ),
      ),
    );
  }
}
