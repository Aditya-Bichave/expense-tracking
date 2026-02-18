import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GroupsRemoteDataSource {
  Future<List<GroupModel>> getGroups();
  Future<GroupModel> createGroup(GroupModel group);
  Future<GroupModel> getGroup(String id);
}

class GroupsRemoteDataSourceImpl implements GroupsRemoteDataSource {
  final SupabaseClient _client;

  GroupsRemoteDataSourceImpl() : _client = SupabaseClientProvider.client;

  @override
  Future<List<GroupModel>> getGroups() async {
    final response = await _client.from('groups').select();
    // Assuming response is a List<dynamic>
    return (response as List).map((e) => GroupModel.fromJson(e)).toList();
  }

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
  Future<GroupModel> getGroup(String id) async {
    final response = await _client
        .from('groups')
        .select()
        .eq('id', id)
        .single();
    return GroupModel.fromJson(response);
  }
}
