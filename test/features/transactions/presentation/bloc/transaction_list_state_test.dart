import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';

void main() {
  test('TransactionListState supports equality', () {
    expect(const TransactionListState(), equals(const TransactionListState()));
  });
}
