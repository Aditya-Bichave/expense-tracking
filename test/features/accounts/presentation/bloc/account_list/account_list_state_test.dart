import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

void main() {
  test('AccountListLoading supports equality', () {
    expect(const AccountListLoading(), equals(const AccountListLoading()));
  });
}
