import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group.dart';
import 'package:expense_tracker/features/groups/domain/usecases/update_group.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class CreateGroupBloc extends Bloc<CreateGroupEvent, CreateGroupState> {
  final CreateGroup _createGroup;
  final UpdateGroup _updateGroup;
  final Uuid _uuid;
  final SupabaseClient? _supabaseClient;

  CreateGroupBloc({
    required CreateGroup createGroup,
    required UpdateGroup updateGroup,
    required Uuid uuid,
    SupabaseClient? supabaseClient,
  }) : _createGroup = createGroup,
       _updateGroup = updateGroup,
       _uuid = uuid,
       _supabaseClient = supabaseClient,
       super(CreateGroupInitial()) {
    on<CreateGroupSubmitted>(_onCreateGroupSubmitted);
  }

  Future<void> _onCreateGroupSubmitted(
    CreateGroupSubmitted event,
    Emitter<CreateGroupState> emit,
  ) async {
    emit(CreateGroupLoading());

    final groupId = event.groupId ?? _uuid.v4();
    var photoUrl = event.existingPhotoUrl;
    final now = DateTime.now();

    if (event.photoFile != null && _supabaseClient != null) {
      photoUrl = await _uploadGroupPhoto(groupId, event.photoFile!, photoUrl);
    }

    final group = GroupEntity(
      id: groupId,
      name: event.name,
      type: event.type,
      currency: event.currency,
      photoUrl: photoUrl,
      createdBy: event.createdBy ?? event.userId,
      createdAt: event.createdAt ?? now,
      updatedAt: now,
      isArchived: event.isArchived,
    );

    final result = event.isEdit
        ? await _updateGroup(group)
        : await _createGroup(group);

    result.fold(
      (failure) => emit(CreateGroupFailure(failure.message)),
      (group) => emit(CreateGroupSuccess(group)),
    );
  }

  Future<String?> _uploadGroupPhoto(
    String groupId,
    File photoFile,
    String? fallbackUrl,
  ) async {
    try {
      final fileName = '$groupId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabaseClient!.storage
          .from('group-avatars')
          .upload(fileName, photoFile);
      return _supabaseClient.storage
          .from('group-avatars')
          .getPublicUrl(fileName);
    } catch (e) {
      log.warning('Failed to upload group photo: $e');
      return fallbackUrl;
    }
  }
}
