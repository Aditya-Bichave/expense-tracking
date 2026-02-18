import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/features/invites/data/models/invite_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class InvitesRemoteDataSource {
  Future<InviteModel> createInvite(String groupId);
  Future<void> acceptInvite(String token);
}

class InvitesRemoteDataSourceImpl implements InvitesRemoteDataSource {
  final SupabaseClient _client;

  InvitesRemoteDataSourceImpl() : _client = SupabaseClientProvider.client;

  @override
  Future<InviteModel> createInvite(String groupId) async {
    final token = DateTime.now().millisecondsSinceEpoch
        .toString(); // Simple token for now

    final response = await _client
        .from('invites')
        .insert({
          'group_id': groupId,
          'token': token,
          'expires_at': DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String(),
        })
        .select()
        .single();

    return InviteModel.fromJson(response);
  }

  @override
  Future<void> acceptInvite(String token) async {
    await _client.functions.invoke('accept-invite', body: {'token': token});
  }
}
