import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_role.g.dart';

@HiveType(typeId: 22)
enum GroupRole {
  @HiveField(0)
  @JsonValue('admin')
  admin,
  @HiveField(1)
  @JsonValue('member')
  member,
  @HiveField(2)
  @JsonValue('viewer')
  viewer,
}
