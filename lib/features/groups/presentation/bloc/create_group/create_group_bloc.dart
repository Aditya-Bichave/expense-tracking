import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';

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

    String? photoUrl;
    final groupId = _uuid.v4();

    if (event.photoFile != null) {
      try {
        final fileName =
            '$groupId-${DateTime.now().millisecondsSinceEpoch}.jpg';
        final response = await Supabase.instance.client.storage
            .from('group-avatars')
            .upload(fileName, event.photoFile!);

        photoUrl = Supabase.instance.client.storage
            .from('group-avatars')
            .getPublicUrl(fileName);
      } catch (e) {
        log.warning('Failed to upload group photo: $e');
        // We continue anyway, just without a photo
      }
    }

    final newGroup = GroupEntity(
      id: groupId,
      name: event.name,
      type: event.type,
      currency: event.currency,
      photoUrl: photoUrl,
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
