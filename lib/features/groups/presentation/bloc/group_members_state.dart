part of 'group_members_bloc.dart';

abstract class GroupMembersState extends Equatable {
  const GroupMembersState();

  @override
  List<Object?> get props => [];
}

class GroupMembersInitial extends GroupMembersState {}

class GroupMembersLoading extends GroupMembersState {}

class GroupMembersLoaded extends GroupMembersState {
  final List<GroupMember> members;

  const GroupMembersLoaded(this.members);

  @override
  List<Object?> get props => [members];
}

class GroupMembersError extends GroupMembersState {
  final String message;

  const GroupMembersError(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupInviteGenerated extends GroupMembersState {
  final String url;

  const GroupInviteGenerated(this.url);

  @override
  List<Object?> get props => [url];
}

class GroupInviteGenerationError extends GroupMembersState {
  final String message;

  const GroupInviteGenerationError(this.message);

  @override
  List<Object?> get props => [message];
}
