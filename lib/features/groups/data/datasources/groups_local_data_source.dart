import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:hive_ce/hive.dart';

abstract class GroupsLocalDataSource {
  Future<void> cacheGroups(List<GroupModel> groups);
  Future<void> addGroup(GroupModel group);
  Future<void> updateGroup(GroupModel group);
  Future<void> deleteGroup(String id);
  List<GroupModel> getGroups();
  GroupModel? getGroup(String id);
}

class GroupsLocalDataSourceImpl implements GroupsLocalDataSource {
  final Box<GroupModel> _box;

  GroupsLocalDataSourceImpl(this._box);

  @override
  Future<void> cacheGroups(List<GroupModel> groups) async {
    final Map<String, GroupModel> groupMap = {
      for (var group in groups) group.id: group,
    };
    await _box.putAll(groupMap);
  }

  @override
  Future<void> addGroup(GroupModel group) async {
    await _box.put(group.id, group);
  }

  @override
  Future<void> updateGroup(GroupModel group) async {
    await _box.put(group.id, group);
  }

  @override
  Future<void> deleteGroup(String id) async {
    await _box.delete(id);
  }

  @override
  List<GroupModel> getGroups() {
    return _box.values.toList();
  }

  @override
  GroupModel? getGroup(String id) {
    return _box.get(id);
  }
}
