import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:equatable/equatable.dart';

class GroupMemberEntity extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final GroupRole role;
  final DateTime joinedAt;

  const GroupMemberEntity({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [id, groupId, userId, role, joinedAt];
}
