import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SettlementsRemoteDataSource {
  Future<List<SettlementModel>> getSettlements(String groupId);
  Future<void> addSettlement(SettlementModel settlement);
}

class SettlementsRemoteDataSourceImpl implements SettlementsRemoteDataSource {
  final SupabaseClient _client;

  SettlementsRemoteDataSourceImpl() : _client = SupabaseClientProvider.client;

  @override
  Future<List<SettlementModel>> getSettlements(String groupId) async {
    final response = await _client
        .from('settlements')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => SettlementModel.fromJson(e)).toList();
  }

  @override
  Future<void> addSettlement(SettlementModel settlement) async {
    await _client.from('settlements').insert(settlement.toJson());
  }
}
