import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';
import 'package:uuid/uuid.dart';

class CreateGroupBloc extends Bloc<CreateGroupEvent, CreateGroupState> {
  final CreateGroup _createGroup;
  final Uuid _uuid;

  CreateGroupBloc({required CreateGroup createGroup, required Uuid uuid})
    : _createGroup = createGroup,
      _uuid = uuid,
      super(CreateGroupInitial()) {
    on<CreateGroupSubmitted>(_onCreateGroupSubmitted);
  }

  Future<void> _onCreateGroupSubmitted(
    CreateGroupSubmitted event,
    Emitter<CreateGroupState> emit,
  ) async {
    emit(CreateGroupLoading());

    final newGroup = GroupEntity(
      id: _uuid.v4(),
      name: event.name,
      type: event.type,
      currency: event.currency,
      createdBy: event.userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isArchived: false,
    );

    final result = await _createGroup(newGroup);

    result.fold(
      (failure) => emit(CreateGroupFailure(failure.message)),
      (group) => emit(CreateGroupSuccess(group)),
    );
  }
}
