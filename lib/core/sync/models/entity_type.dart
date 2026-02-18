import 'package:hive_ce/hive.dart';

part 'entity_type.g.dart';

@HiveType(typeId: 20)
enum EntityType {
  @HiveField(0)
  group,
  @HiveField(1)
  groupMember,
  @HiveField(2)
  groupExpense,
  @HiveField(3)
  settlement,
  @HiveField(4)
  invite,
}
