import 'package:equatable/equatable.dart';

class InviteEntity extends Equatable {
  final String id;
  final String groupId;
  final String token;
  final DateTime expiresAt;
  final int maxUses;
  final int usesCount;

  const InviteEntity({
    required this.id,
    required this.groupId,
    required this.token,
    required this.expiresAt,
    required this.maxUses,
    required this.usesCount,
  });

  @override
  List<Object?> get props => [id, groupId, token, expiresAt, maxUses, usesCount];
}
