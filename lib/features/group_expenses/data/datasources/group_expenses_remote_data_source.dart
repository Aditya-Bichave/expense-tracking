import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

abstract class GroupExpensesRemoteDataSource {
  Future<GroupExpenseModel> createExpense(GroupExpenseModel expense);
  Future<GroupExpenseModel> updateExpense(GroupExpenseModel expense);
  Future<void> deleteExpense(String expenseId);
  Future<List<GroupExpenseModel>> getExpenses(String groupId);
}

class GroupExpensesRemoteDataSourceImpl
    implements GroupExpensesRemoteDataSource {
  final SupabaseClient _client;

  GroupExpensesRemoteDataSourceImpl(this._client);

  @override
  Future<GroupExpenseModel> createExpense(GroupExpenseModel expense) async {
    final expenseData = expense.toJson();
    expenseData.remove('payers');
    expenseData.remove('splits');

    await _client.from('expenses').insert(expenseData).select().single();

    if (expense.payers.isNotEmpty) {
      final payersData = expense.payers
          .map(
            (p) => {
              'expense_id': expense.id,
              'payer_user_id': p.userId,
              'amount': p.amount,
            },
          )
          .toList();
      await _client.from('expense_payers').insert(payersData);
    }

    if (expense.splits.isNotEmpty) {
      final splitsData = expense.splits
          .map(
            (s) => {
              'expense_id': expense.id,
              'user_id': s.userId,
              'amount': s.amount,
              'split_type': s.splitTypeValue,
            },
          )
          .toList();
      await _client.from('expense_splits').insert(splitsData);
    }

    return expense;
  }

  @override
  Future<GroupExpenseModel> updateExpense(GroupExpenseModel expense) async {
    final expenseData = expense.toJson();
    expenseData.remove('id');
    expenseData.remove('created_at');
    expenseData.remove('payers');
    expenseData.remove('splits');

    final payersData = expense.payers
        .map((p) => {'payer_user_id': p.userId, 'amount': p.amount})
        .toList();

    final splitsData = expense.splits
        .map(
          (s) => {
            'user_id': s.userId,
            'amount': s.amount,
            'split_type': s.splitTypeValue,
          },
        )
        .toList();

    // Call the RPC function to atomically update relations and expense data
    await _client.rpc(
      'update_expense_with_relations',
      params: {
        'p_expense_id': expense.id,
        'p_expense_data': expenseData,
        'p_payers': payersData,
        'p_splits': splitsData,
      },
    );

    return expense;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }

  @override
  Future<List<GroupExpenseModel>> getExpenses(String groupId) async {
    final response = await _client
        .from('expenses')
        .select('*, expense_payers(*), expense_splits(*)')
        .eq('group_id', groupId);

    return (response as List).map((e) {
      final Map<String, dynamic> data = e as Map<String, dynamic>;
      data['payers'] = (data['expense_payers'] as List)
          .map((p) => {'userId': p['payer_user_id'], 'amount': p['amount']})
          .toList();
      data['splits'] = (data['expense_splits'] as List)
          .map(
            (s) => {
              'userId': s['user_id'],
              'amount': s['amount'],
              'splitTypeValue': s['split_type'],
            },
          )
          .toList();

      return GroupExpenseModel.fromJson(data);
    }).toList();
  }
}
