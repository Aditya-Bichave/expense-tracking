import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:hive_ce/hive.dart';

abstract class GroupMembersLocalDataSource {
  Future<void> cacheMembers(List<GroupMemberModel> members);
  List<GroupMemberModel> getMembersForGroup(String groupId);
}

class GroupMembersLocalDataSourceImpl implements GroupMembersLocalDataSource {
  final Box<GroupMemberModel> _box;

  GroupMembersLocalDataSourceImpl(this._box);

  @override
  Future<void> cacheMembers(List<GroupMemberModel> members) async {
    final Map<String, GroupMemberModel> map = {
      for (var m in members) m.id: m,
    };
    await _box.putAll(map);
  }

  @override
  List<GroupMemberModel> getMembersForGroup(String groupId) {
    return _box.values.where((m) => m.groupId == groupId).toList();
  }
}
