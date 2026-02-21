import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';

void main() {
  group('TransactionListState', () {
    test('has correct default values', () {
      const state = TransactionListState();
      expect(state.status, ListStatus.initial);
      expect(state.transactions, isEmpty);
      expect(state.isInBatchEditMode, false);
      expect(state.selectedTransactionIds, isEmpty);
    });

    test('supports equality with same values', () {
      expect(
        const TransactionListState(),
        equals(const TransactionListState()),
      );
    });

    test('supports inequality with different status', () {
      expect(
        const TransactionListState(status: ListStatus.loading),
        isNot(equals(const TransactionListState(status: ListStatus.success))),
      );
    });

    test('has all expected status values', () {
      expect(ListStatus.values.length, 4);
      expect(ListStatus.values, contains(ListStatus.initial));
      expect(ListStatus.values, contains(ListStatus.loading));
      expect(ListStatus.values, contains(ListStatus.success));
      expect(ListStatus.values, contains(ListStatus.error));
    });

    test('has all expected sort direction values', () {
      expect(SortDirection.values.length, 2);
      expect(SortDirection.values, contains(SortDirection.asc));
      expect(SortDirection.values, contains(SortDirection.desc));
    });

    test('has all expected sort by values', () {
      expect(TransactionSortBy.values.length, 3);
      expect(TransactionSortBy.values, contains(TransactionSortBy.date));
      expect(TransactionSortBy.values, contains(TransactionSortBy.amount));
      expect(TransactionSortBy.values, contains(TransactionSortBy.title));
    });
  });
}