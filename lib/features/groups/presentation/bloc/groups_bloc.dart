import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/e2e_mode.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/usecases/sync_groups.dart';
import 'package:expense_tracker/features/groups/domain/usecases/watch_groups.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GroupsEvent extends Equatable {
  const GroupsEvent();

  @override
  List<Object?> get props => [];
}

class LoadGroups extends GroupsEvent {
  const LoadGroups();
}

class RefreshGroups extends GroupsEvent {
  final bool showLoading;

  const RefreshGroups({this.showLoading = false});

  @override
  List<Object?> get props => [showLoading];
}

class _GroupsUpdated extends GroupsEvent {
  final Either<Failure, List<GroupEntity>> result;

  const _GroupsUpdated(this.result);

  @override
  List<Object?> get props => [result];
}

class _GroupsStreamFailed extends GroupsEvent {
  final String message;

  const _GroupsStreamFailed(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class GroupsState extends Equatable {
  const GroupsState();

  @override
  List<Object?> get props => [];
}

class GroupsInitial extends GroupsState {
  const GroupsInitial();
}

class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

class GroupsLoaded extends GroupsState {
  final List<GroupEntity> groups;

  const GroupsLoaded(this.groups);

  @override
  List<Object?> get props => [groups];
}

class GroupsError extends GroupsState {
  final String message;

  const GroupsError(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  final WatchGroups _watchGroups;
  final SyncGroups _syncGroups;

  StreamSubscription<Either<Failure, List<GroupEntity>>>? _groupsSubscription;

  GroupsBloc({required WatchGroups watchGroups, required SyncGroups syncGroups})
    : _watchGroups = watchGroups,
      _syncGroups = syncGroups,
      super(const GroupsInitial()) {
    on<LoadGroups>(_onLoadGroups);
    on<RefreshGroups>(_onRefreshGroups);
    on<_GroupsUpdated>(_onGroupsUpdated);
    on<_GroupsStreamFailed>(_onGroupsStreamFailed);
  }

  Future<void> _onLoadGroups(
    LoadGroups event,
    Emitter<GroupsState> emit,
  ) async {
    if (_groupsSubscription != null) {
      return;
    }

    emit(const GroupsLoading());

    // Trigger sync in background but handle errors to prevent silent failures
    if (!E2EMode.enabled) {
      try {
        final result = await _syncGroups();
        result.fold(
          (failure) => log.warning("Group sync failed: ${failure.message}"),
          (_) => log.info("Group sync completed successfully."),
        );
      } catch (e, s) {
      log.severe("Msg: $e\n$s");
        log.severe("Group sync threw exception: $e\n$s");
      }
    }

    _groupsSubscription = _watchGroups().listen(
      (result) => add(_GroupsUpdated(result)),
      onError: (Object error, StackTrace stackTrace) {
        add(_GroupsStreamFailed(error.toString()));
      },
      cancelOnError:
          false, // Ensure subscription stays active even if watch throws
    );
  }

  Future<void> _onRefreshGroups(
    RefreshGroups event,
    Emitter<GroupsState> emit,
  ) async {
    if (_groupsSubscription == null) {
      add(const LoadGroups());
      return;
    }

    if (event.showLoading && state is! GroupsLoaded) {
      emit(const GroupsLoading());
    }

    if (!E2EMode.enabled) {
      await _triggerSync();
    }
  }

  void _onGroupsUpdated(_GroupsUpdated event, Emitter<GroupsState> emit) {
    event.result.fold(
      (failure) => emit(GroupsError(failure.message)),
      (groups) => emit(GroupsLoaded(groups)),
    );
  }

  void _onGroupsStreamFailed(
    _GroupsStreamFailed event,
    Emitter<GroupsState> emit,
  ) {
    emit(GroupsError(event.message));
  }

  Future<void> _triggerSync() async {
    try {
      final result = await _syncGroups();
      result.fold(
        (failure) => log.warning('Group sync failed: ${failure.message}'),
        (_) => log.info('Group sync completed successfully.'),
      );
    } catch (error, stackTrace) {
      log.severe('Group sync threw exception: $error\n$stackTrace');
    }
  }

  @override
  Future<void> close() async {
    await _groupsSubscription?.cancel();
    return super.close();
  }
}
