import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';

void main() {
  test('AddEditTransactionState supports equality', () {
    expect(
      const AddEditTransactionState(),
      equals(const AddEditTransactionState()),
    );
  });
}
