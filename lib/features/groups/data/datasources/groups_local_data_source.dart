import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:rxdart/rxdart.dart';

abstract class GroupsLocalDataSource {
  Future<void> saveGroup(GroupModel group);
  Future<void> saveGroups(List<GroupModel> groups);
  List<GroupModel> getGroups();
  Stream<List<GroupModel>> watchGroups();
  Future<void> saveGroupMembers(List<GroupMemberModel> members);
  List<GroupMemberModel> getGroupMembers(String groupId);
  Future<void> deleteGroup(String groupId);
  Future<void> deleteMember(String memberId);
}

class GroupsLocalDataSourceImpl implements GroupsLocalDataSource {
  final Box<GroupModel> _groupBox;
  final Box<GroupMemberModel> _memberBox;

  GroupsLocalDataSourceImpl(this._groupBox, this._memberBox);

  @override
  Future<void> saveGroup(GroupModel group) async {
    await _groupBox.put(group.id, group);
  }

  @override
  Future<void> saveGroups(List<GroupModel> groups) async {
    final map = {for (var g in groups) g.id: g};
    await _groupBox.putAll(map);
  }

  @override
  List<GroupModel> getGroups() {
    return _groupBox.values.toList();
  }

  @override
  Stream<List<GroupModel>> watchGroups() {
    return _groupBox
        .watch()
        .map((_) {
          return _groupBox.values.toList();
        })
        .startWith(_groupBox.values.toList());
  }

  @override
  Future<void> saveGroupMembers(List<GroupMemberModel> members) async {
    final map = {for (var m in members) m.id: m};
    await _memberBox.putAll(map);
  }

  @override
  List<GroupMemberModel> getGroupMembers(String groupId) {
    return _memberBox.values.where((m) => m.groupId == groupId).toList();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _groupBox.delete(groupId);
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await _memberBox.delete(memberId);
  }
}
