import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class GroupsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadGroups extends GroupsEvent {}

class CreateGroupRequested extends GroupsEvent {
  final String name;
  final String userId;
  CreateGroupRequested(this.name, this.userId);
}

class JoinGroupRequested extends GroupsEvent {
  final String token;
  JoinGroupRequested(this.token);
}

// States
abstract class GroupsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GroupsInitial extends GroupsState {}

class GroupsLoading extends GroupsState {}

class GroupsLoaded extends GroupsState {
  final List<GroupEntity> groups;
  GroupsLoaded(this.groups);
  @override
  List<Object?> get props => [groups];
}

class GroupsError extends GroupsState {
  final String message;
  GroupsError(this.message);
  @override
  List<Object?> get props => [message];
}

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  final GroupsRepository _repository;
  final Uuid _uuid = const Uuid();

  GroupsBloc(this._repository) : super(GroupsInitial()) {
    on<LoadGroups>(_onLoadGroups);
    on<CreateGroupRequested>(_onCreateGroup);
    on<JoinGroupRequested>(_onJoinGroup);
  }

  Future<void> _onLoadGroups(
    LoadGroups event,
    Emitter<GroupsState> emit,
  ) async {
    emit(GroupsLoading());
    final result = await _repository.getGroups();
    result.fold(
      (failure) => emit(GroupsError(failure.message)),
      (groups) => emit(GroupsLoaded(groups)),
    );

    _repository.syncGroups().then((_) {
      add(LoadGroups());
    });
  }

  Future<void> _onCreateGroup(
    CreateGroupRequested event,
    Emitter<GroupsState> emit,
  ) async {
    final newGroup = GroupEntity(
      id: _uuid.v4(),
      name: event.name,
      createdBy: event.userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _repository.createGroup(newGroup);
    result.fold(
      (failure) => emit(GroupsError(failure.message)),
      (group) => add(LoadGroups()),
    );
  }

  Future<void> _onJoinGroup(
    JoinGroupRequested event,
    Emitter<GroupsState> emit,
  ) async {
    emit(GroupsLoading());
    final result = await _repository.acceptInvite(event.token);
    result.fold(
      (failure) => emit(GroupsError(failure.message)),
      (_) => add(LoadGroups()),
    );
  }
}
