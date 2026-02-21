import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

void main() {
  group('AccountListState', () {
    group('AccountListInitial', () {
      test('supports equality', () {
        expect(
          const AccountListInitial(),
          equals(const AccountListInitial()),
        );
      });

      test('has empty props', () {
        expect(const AccountListInitial().props, isEmpty);
      });
    });

    group('AccountListLoading', () {
      test('supports equality with default isReloading', () {
        expect(
          const AccountListLoading(),
          equals(const AccountListLoading()),
        );
      });

      test('supports equality with same isReloading value', () {
        expect(
          const AccountListLoading(isReloading: true),
          equals(const AccountListLoading(isReloading: true)),
        );
        expect(
          const AccountListLoading(isReloading: false),
          equals(const AccountListLoading(isReloading: false)),
        );
      });

      test('supports inequality with different isReloading', () {
        expect(
          const AccountListLoading(isReloading: true),
          isNot(equals(const AccountListLoading(isReloading: false))),
        );
      });

      test('has correct default isReloading value', () {
        const state = AccountListLoading();
        expect(state.isReloading, false);
      });

      test('stores isReloading value correctly', () {
        const state = AccountListLoading(isReloading: true);
        expect(state.isReloading, true);
      });

      test('props include isReloading', () {
        const state = AccountListLoading(isReloading: true);
        expect(state.props, [true]);
      });
    });

    group('AccountListLoaded', () {
      final mockAccount1 = AssetAccount(
        id: '1',
        name: 'Test Account 1',
        type: AssetAccountType.cash,
        balance: 100.0,
        createdAt: DateTime(2023),
      );

      final mockAccount2 = AssetAccount(
        id: '2',
        name: 'Test Account 2',
        type: AssetAccountType.bankAccount,
        balance: 200.0,
        createdAt: DateTime(2023),
      );

      test('supports equality with same accounts', () {
        final state1 = AccountListLoaded(accounts: [mockAccount1]);
        final state2 = AccountListLoaded(accounts: [mockAccount1]);
        expect(state1, equals(state2));
      });

      test('supports inequality with different accounts', () {
        final state1 = AccountListLoaded(accounts: [mockAccount1]);
        final state2 = AccountListLoaded(accounts: [mockAccount2]);
        expect(state1, isNot(equals(state2)));
      });

      test('stores accounts correctly', () {
        final state = AccountListLoaded(accounts: [mockAccount1, mockAccount2]);
        expect(state.accounts, [mockAccount1, mockAccount2]);
        expect(state.items, [mockAccount1, mockAccount2]);
      });

      test('can have empty accounts list', () {
        const state = AccountListLoaded(accounts: []);
        expect(state.accounts, isEmpty);
        expect(state.items, isEmpty);
      });

      test('filtersApplied returns false when no filters', () {
        final state = AccountListLoaded(accounts: [mockAccount1]);
        expect(state.filtersApplied, false);
      });

      test('all filter fields are null', () {
        final state = AccountListLoaded(accounts: [mockAccount1]);
        expect(state.filterStartDate, null);
        expect(state.filterEndDate, null);
        expect(state.filterCategory, null);
        expect(state.filterAccountId, null);
      });

      test('props include all fields', () {
        final state = AccountListLoaded(accounts: [mockAccount1]);
        expect(state.props.length, 5);
        expect(state.props[0], [mockAccount1]);
      });
    });

    group('AccountListError', () {
      test('supports equality with same message', () {
        expect(
          const AccountListError('error'),
          equals(const AccountListError('error')),
        );
      });

      test('supports inequality with different message', () {
        expect(
          const AccountListError('error1'),
          isNot(equals(const AccountListError('error2'))),
        );
      });

      test('stores message correctly', () {
        const state = AccountListError('Test error message');
        expect(state.message, 'Test error message');
      });

      test('props include message', () {
        const state = AccountListError('error');
        expect(state.props, ['error']);
      });
    });

    test('all states extend AccountListState', () {
      expect(const AccountListInitial(), isA<AccountListState>());
      expect(const AccountListLoading(), isA<AccountListState>());
      expect(const AccountListLoaded(accounts: []), isA<AccountListState>());
      expect(const AccountListError(''), isA<AccountListState>());
    });

    test('different state types are not equal', () {
      expect(
        const AccountListInitial(),
        isNot(equals(const AccountListLoading())),
      );
      expect(
        const AccountListLoading(),
        isNot(equals(const AccountListError(''))),
      );
    });
  });
}