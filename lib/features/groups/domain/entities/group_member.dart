import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';

class GroupMember extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final GroupRole role;
  final DateTime joinedAt;
  final DateTime updatedAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, groupId, userId, role, joinedAt, updatedAt];
}
