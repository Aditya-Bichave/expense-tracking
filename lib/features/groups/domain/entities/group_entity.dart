import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';

class GroupEntity extends Equatable {
  final String id;
  final String name;
  final GroupType type;
  final String currency;
  final String? photoUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  const GroupEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.photoUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  GroupEntity copyWith({
    String? id,
    String? name,
    GroupType? type,
    String? currency,
    Object? photoUrl = _sentinel,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      photoUrl: identical(photoUrl, _sentinel)
          ? this.photoUrl
          : photoUrl as String?,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    currency,
    photoUrl,
    createdBy,
    createdAt,
    updatedAt,
    isArchived,
  ];
}

const Object _sentinel = Object();
