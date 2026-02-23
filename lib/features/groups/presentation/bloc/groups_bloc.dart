import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/usecases/watch_groups.dart';
import 'package:expense_tracker/features/groups/domain/usecases/sync_groups.dart';
import 'package:expense_tracker/features/groups/domain/usecases/join_group.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';

// Events
abstract class GroupsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadGroups extends GroupsEvent {}

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
  final WatchGroups _watchGroups;
  final SyncGroups _syncGroups;

  // JoinGroup is ignored in Phase 2A, removed to simplify BLoC and avoid concurrency issues.
  // final JoinGroup _joinGroup;

  GroupsBloc({
    required WatchGroups watchGroups,
    required SyncGroups syncGroups,
    required JoinGroup
    joinGroup, // Constructor still accepts it to avoid breaking DI immediately, but unused
  }) : _watchGroups = watchGroups,
       _syncGroups = syncGroups,
       super(GroupsInitial()) {
    on<LoadGroups>(_onLoadGroups);
  }

  Future<void> _onLoadGroups(
    LoadGroups event,
    Emitter<GroupsState> emit,
  ) async {
    emit(GroupsLoading());
    _syncGroups(); // Trigger sync in background

    await emit.forEach<Either<Failure, List<GroupEntity>>>(
      _watchGroups(),
      onData: (result) {
        return result.fold(
          (failure) => GroupsError(failure.message),
          (groups) => GroupsLoaded(groups),
        );
      },
    );
  }
}
