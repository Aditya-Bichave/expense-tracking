import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GroupMembersRemoteDataSource {
  Future<List<GroupMemberModel>> getMembers(String groupId);
  Future<void> addMember(GroupMemberModel member);
}

class GroupMembersRemoteDataSourceImpl implements GroupMembersRemoteDataSource {
  final SupabaseClient _client;

  GroupMembersRemoteDataSourceImpl() : _client = SupabaseClientProvider.client;

  @override
  Future<List<GroupMemberModel>> getMembers(String groupId) async {
    final response = await _client
        .from('group_members')
        .select()
        .eq('group_id', groupId);
    return (response as List).map((e) => GroupMemberModel.fromJson(e)).toList();
  }

  @override
  Future<void> addMember(GroupMemberModel member) async {
    await _client.from('group_members').insert(member.toJson());
  }
}
