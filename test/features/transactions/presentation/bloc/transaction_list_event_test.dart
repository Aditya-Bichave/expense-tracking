import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';

void main() {
  test('LoadTransactions supports equality', () {
    expect(const LoadTransactions(), equals(const LoadTransactions()));
  });
}
