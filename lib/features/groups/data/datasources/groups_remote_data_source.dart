import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GroupsRemoteDataSource {
  Future<GroupModel> createGroup(GroupModel group);
  Future<List<GroupModel>> getGroups();
  Future<List<GroupMemberModel>> getGroupMembers(String groupId);
  Future<String> createInvite(
    String groupId, {
    String role = 'member',
    int expiryDays = 7,
    int maxUses = 0,
  });
  Future<Map<String, dynamic>> acceptInvite(String token);
  Future<void> updateMemberRole(String groupId, String userId, String role);
  Future<void> removeMember(String groupId, String userId);
}

class GroupsRemoteDataSourceImpl implements GroupsRemoteDataSource {
  final SupabaseClient _client;

  GroupsRemoteDataSourceImpl(this._client);

  @override
  Future<GroupModel> createGroup(GroupModel group) async {
    final response = await _client
        .from('groups')
        .insert(group.toJson())
        .select()
        .single();
    return GroupModel.fromJson(response);
  }

  @override
  Future<List<GroupModel>> getGroups() async {
    final response = await _client.from('groups').select();
    return (response as List).map((e) => GroupModel.fromJson(e)).toList();
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final response = await _client
        .from('group_members')
        .select()
        .eq('group_id', groupId);
    return (response as List).map((e) => GroupMemberModel.fromJson(e)).toList();
  }

  @override
  Future<String> createInvite(
    String groupId, {
    String role = 'member',
    int expiryDays = 7,
    int maxUses = 0,
  }) async {
    final response = await _client.functions.invoke(
      'create-invite',
      body: {
        'group_id': groupId,
        'role': role,
        'expiry_days': expiryDays,
        'max_uses': maxUses,
      },
    );
    if (response.status != 200) {
      throw Exception(
        'Failed to create invite: ${response.status} ${response.data}',
      );
    }
    return response.data['invite_url'];
  }

  @override
  Future<Map<String, dynamic>> acceptInvite(String token) async {
    final response = await _client.functions.invoke(
      'join_group_via_invite',
      body: {'token': token},
    );
    if (response.status != 200) {
      throw Exception(
        'Failed to accept invite: ${response.status} ${response.data}',
      );
    }
    return response.data;
  }

  @override
  Future<void> updateMemberRole(
    String groupId,
    String userId,
    String role,
  ) async {
    await _client
        .from('group_members')
        .update({'role': role})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }
}
