import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group_usecase.dart';
import 'package:expense_tracker/features/groups/domain/usecases/get_groups_usecase.dart';
import 'package:expense_tracker/features/groups/domain/usecases/sync_groups_usecase.dart';

// Events
abstract class GroupListEvent extends Equatable {
  const GroupListEvent();
  @override
  List<Object?> get props => [];
}

class LoadGroups extends GroupListEvent {}

class CreateGroup extends GroupListEvent {
  final String name;
  const CreateGroup(this.name);
  @override
  List<Object?> get props => [name];
}

class RefreshGroups extends GroupListEvent {}

// States
abstract class GroupListState extends Equatable {
  const GroupListState();
  @override
  List<Object?> get props => [];
}

class GroupListInitial extends GroupListState {}

class GroupListLoading extends GroupListState {}

class GroupListLoaded extends GroupListState {
  final List<GroupEntity> groups;
  const GroupListLoaded(this.groups);
  @override
  List<Object?> get props => [groups];
}

class GroupListError extends GroupListState {
  final String message;
  const GroupListError(this.message);
  @override
  List<Object?> get props => [message];
}

class GroupListBloc extends Bloc<GroupListEvent, GroupListState> {
  final GetGroupsUseCase _getGroupsUseCase;
  final CreateGroupUseCase _createGroupUseCase;
  final SyncGroupsUseCase _syncGroupsUseCase;

  GroupListBloc({
    required GetGroupsUseCase getGroupsUseCase,
    required CreateGroupUseCase createGroupUseCase,
    required SyncGroupsUseCase syncGroupsUseCase,
  }) : _getGroupsUseCase = getGroupsUseCase,
       _createGroupUseCase = createGroupUseCase,
       _syncGroupsUseCase = syncGroupsUseCase,
       super(GroupListInitial()) {
    on<LoadGroups>(_onLoadGroups);
    on<CreateGroup>(_onCreateGroup);
    on<RefreshGroups>(_onRefreshGroups);
  }

  Future<void> _onLoadGroups(
    LoadGroups event,
    Emitter<GroupListState> emit,
  ) async {
    emit(GroupListLoading());
    final result = await _getGroupsUseCase(const NoParams());
    result.fold(
      (failure) => emit(GroupListError(failure.message)),
      (groups) => emit(GroupListLoaded(groups)),
    );
  }

  Future<void> _onCreateGroup(
    CreateGroup event,
    Emitter<GroupListState> emit,
  ) async {
    // Optimistic update handled by repository but Bloc needs to reload or append
    final result = await _createGroupUseCase(
      CreateGroupParams(name: event.name),
    );
    result.fold((failure) => emit(GroupListError(failure.message)), (group) {
      if (state is GroupListLoaded) {
        final currentGroups = (state as GroupListLoaded).groups;
        emit(GroupListLoaded([...currentGroups, group]));
      } else {
        add(LoadGroups());
      }
    });
  }

  Future<void> _onRefreshGroups(
    RefreshGroups event,
    Emitter<GroupListState> emit,
  ) async {
    await _syncGroupsUseCase(const NoParams());
    add(LoadGroups());
  }
}
