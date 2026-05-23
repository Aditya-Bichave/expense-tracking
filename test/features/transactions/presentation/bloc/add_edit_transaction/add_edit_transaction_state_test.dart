import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddEditTransactionState', () {
    test('supports value comparisons', () {
      expect(const AddEditTransactionState(), const AddEditTransactionState());
    });

    test('copyWith works correctly', () {
      final state = const AddEditTransactionState().copyWith(
        status: AddEditStatus.success,
        tempAmount: 100,
        tempTitle: 'Test',
      );

      expect(state.status, AddEditStatus.success);
      expect(state.tempAmount, 100);
      expect(state.tempTitle, 'Test');
    });
  });
}
