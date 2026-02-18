import 'package:hive_ce/hive.dart';

part 'op_type.g.dart';

@HiveType(typeId: 21)
enum OpType {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}
