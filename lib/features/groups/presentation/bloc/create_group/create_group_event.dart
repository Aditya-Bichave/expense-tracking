import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';

abstract class CreateGroupEvent extends Equatable {
  const CreateGroupEvent();

  @override
  List<Object?> get props => [];
}

class CreateGroupSubmitted extends CreateGroupEvent {
  final String name;
  final GroupType type;
  final String currency;
  final String userId;
  final String? groupId;
  final String? createdBy;
  final DateTime? createdAt;
  final String? existingPhotoUrl;
  final bool isArchived;
  final File? photoFile;

  const CreateGroupSubmitted({
    required this.name,
    required this.type,
    required this.currency,
    required this.userId,
    this.groupId,
    this.createdBy,
    this.createdAt,
    this.existingPhotoUrl,
    this.isArchived = false,
    this.photoFile,
  });

  bool get isEdit => groupId != null;

  @override
  List<Object?> get props => [
    name,
    type,
    currency,
    userId,
    groupId,
    createdBy,
    createdAt,
    existingPhotoUrl,
    isArchived,
    photoFile,
  ];
}
