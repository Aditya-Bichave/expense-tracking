import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/features/groups/data/models/group_expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GroupExpensesRemoteDataSource {
  Future<List<GroupExpenseModel>> getExpenses(String groupId);
  Future<void> addExpense(GroupExpenseModel expense);
}

class GroupExpensesRemoteDataSourceImpl implements GroupExpensesRemoteDataSource {
  final SupabaseClient _client;

  GroupExpensesRemoteDataSourceImpl() : _client = SupabaseClientProvider.client;

  @override
  Future<List<GroupExpenseModel>> getExpenses(String groupId) async {
    final response = await _client
        .from('expenses')
        .select()
        .eq('group_id', groupId)
        .order('occurred_at', ascending: false);
    return (response as List).map((e) => GroupExpenseModel.fromJson(e)).toList();
  }

  @override
  Future<void> addExpense(GroupExpenseModel expense) async {
    await _client.from('expenses').insert(expense.toJson());
  }
}
