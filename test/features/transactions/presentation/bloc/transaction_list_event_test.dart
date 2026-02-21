import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';

void main() {
  group('TransactionListEvent', () {
    group('LoadTransactions', () {
      test('supports equality with default values', () {
        expect(const LoadTransactions(), equals(const LoadTransactions()));
      });

      test('supports equality with same forceReload', () {
        expect(
          const LoadTransactions(forceReload: true),
          equals(const LoadTransactions(forceReload: true)),
        );
      });

      test('has correct default forceReload value', () {
        const event = LoadTransactions();
        expect(event.forceReload, false);
      });
    });

    group('FilterChanged', () {
      test('supports equality with same values', () {
        expect(
          FilterChanged(categoryId: 'cat1'),
          equals(FilterChanged(categoryId: 'cat1')),
        );
      });

      test('can have null values', () {
        const event = FilterChanged();
        expect(event.startDate, null);
        expect(event.endDate, null);
        expect(event.categoryId, null);
        expect(event.accountId, null);
        expect(event.transactionType, null);
      });
    });

    group('SortChanged', () {
      test('supports equality with same values', () {
        expect(
          SortChanged(sortBy: TransactionSortBy.date, sortDirection: SortDirection.desc),
          equals(SortChanged(sortBy: TransactionSortBy.date, sortDirection: SortDirection.desc)),
        );
      });
    });

    group('SearchChanged', () {
      test('supports equality with same search term', () {
        expect(
          SearchChanged(searchTerm: 'test'),
          equals(SearchChanged(searchTerm: 'test')),
        );
      });

      test('can have null search term', () {
        const event = SearchChanged();
        expect(event.searchTerm, null);
      });
    });

    group('ToggleBatchEdit', () {
      test('supports equality', () {
        expect(const ToggleBatchEdit(), equals(const ToggleBatchEdit()));
      });
    });

    group('ResetState', () {
      test('supports equality', () {
        expect(const ResetState(), equals(const ResetState()));
      });
    });
  });
}