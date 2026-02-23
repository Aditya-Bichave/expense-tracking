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
