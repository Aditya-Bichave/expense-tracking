import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';

void main() {
  group('AccountListEvent', () {
    group('LoadAccounts', () {
      test('supports equality with default forceReload', () {
        expect(const LoadAccounts(), equals(const LoadAccounts()));
      });

      test('supports equality with same forceReload value', () {
        expect(
          const LoadAccounts(forceReload: true),
          equals(const LoadAccounts(forceReload: true)),
        );
        expect(
          const LoadAccounts(forceReload: false),
          equals(const LoadAccounts(forceReload: false)),
        );
      });

      test('supports inequality with different forceReload', () {
        expect(
          const LoadAccounts(forceReload: true),
          isNot(equals(const LoadAccounts(forceReload: false))),
        );
      });

      test('has correct default forceReload value', () {
        const event = LoadAccounts();
        expect(event.forceReload, false);
      });

      test('stores forceReload value correctly', () {
        const event = LoadAccounts(forceReload: true);
        expect(event.forceReload, true);
      });

      test('props include forceReload', () {
        const event = LoadAccounts(forceReload: true);
        expect(event.props, [true]);
      });
    });

    group('DeleteAccountRequested', () {
      test('supports equality with same accountId', () {
        expect(
          const DeleteAccountRequested('123'),
          equals(const DeleteAccountRequested('123')),
        );
      });

      test('supports inequality with different accountId', () {
        expect(
          const DeleteAccountRequested('123'),
          isNot(equals(const DeleteAccountRequested('456'))),
        );
      });

      test('stores accountId correctly', () {
        const event = DeleteAccountRequested('test-id');
        expect(event.accountId, 'test-id');
      });

      test('props include accountId', () {
        const event = DeleteAccountRequested('abc');
        expect(event.props, ['abc']);
      });
    });

    group('ResetState', () {
      test('supports equality', () {
        expect(const ResetState(), equals(const ResetState()));
      });

      test('has empty props', () {
        const event = ResetState();
        expect(event.props, isEmpty);
      });
    });

    test('all events extend AccountListEvent', () {
      expect(const LoadAccounts(), isA<AccountListEvent>());
      expect(const DeleteAccountRequested(''), isA<AccountListEvent>());
      expect(const ResetState(), isA<AccountListEvent>());
    });

    test('different event types are not equal', () {
      expect(
        const LoadAccounts(),
        isNot(equals(const ResetState())),
      );
      expect(
        const DeleteAccountRequested('id'),
        isNot(equals(const LoadAccounts())),
      );
    });
  });
}