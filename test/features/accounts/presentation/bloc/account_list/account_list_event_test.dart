import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';

void main() {
  test('LoadAccounts supports equality', () {
    expect(const LoadAccounts(), equals(const LoadAccounts()));
  });
}
