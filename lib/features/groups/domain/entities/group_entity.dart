import 'package:equatable/equatable.dart';

class GroupEntity extends Equatable {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount; // For UI display

  const GroupEntity({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 1,
  });

  @override
  List<Object?> get props => [id, name, createdBy, createdAt, updatedAt, memberCount];
}
