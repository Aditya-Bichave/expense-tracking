import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

part 'group_members_event.dart';
part 'group_members_state.dart';

class GroupMembersBloc extends Bloc<GroupMembersEvent, GroupMembersState> {
  final GroupsRepository _repository;

  GroupMembersBloc(this._repository) : super(GroupMembersInitial()) {
    on<LoadGroupMembers>(_onLoadGroupMembers);
    on<GenerateInviteLink>(_onGenerateInviteLink);
    on<ChangeMemberRole>(_onChangeMemberRole);
    on<KickMember>(_onKickMember);
  }

  Future<void> _onLoadGroupMembers(
    LoadGroupMembers event,
    Emitter<GroupMembersState> emit,
  ) async {
    emit(GroupMembersLoading());
    final result = await _repository.getGroupMembers(event.groupId);
    result.fold(
      (failure) => emit(GroupMembersError(failure.message)),
      (members) => emit(GroupMembersLoaded(members)),
    );
  }

  Future<void> _onGenerateInviteLink(
    GenerateInviteLink event,
    Emitter<GroupMembersState> emit,
  ) async {
    final result = await _repository.createInvite(
      event.groupId,
      role: event.role,
      expiryDays: event.expiryDays,
      maxUses: event.maxUses,
    );
    result.fold(
      (failure) => emit(GroupInviteGenerationError(failure.message)),
      (url) => emit(GroupInviteGenerated(url)),
    );
  }

  Future<void> _onChangeMemberRole(
    ChangeMemberRole event,
    Emitter<GroupMembersState> emit,
  ) async {
    final result = await _repository.updateMemberRole(
      event.groupId,
      event.userId,
      event.newRole,
    );
    result.fold(
      (failure) => emit(GroupMembersError(failure.message)),
      (_) => add(LoadGroupMembers(event.groupId)),
    );
  }

  Future<void> _onKickMember(
    KickMember event,
    Emitter<GroupMembersState> emit,
  ) async {
    final result = await _repository.removeMember(event.groupId, event.userId);
    result.fold(
      (failure) => emit(GroupMembersError(failure.message)),
      (_) => add(LoadGroupMembers(event.groupId)),
    );
  }
}
