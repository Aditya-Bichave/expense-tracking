
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAssetAccountsUseCase extends Mock
    implements GetAssetAccountsUseCase {}

class MockDeleteAssetAccountUseCase extends Mock
    implements DeleteAssetAccountUseCase {}

class FakeDeleteAssetAccountParams extends Fake
    implements DeleteAssetAccountParams {}

void main() {
  late AccountListBloc bloc;
  late MockGetAssetAccountsUseCase mockGetAccounts;
  late MockDeleteAssetAccountUseCase mockDeleteAccount;
  late StreamController<DataChangedEvent> dataChangeController;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeDeleteAssetAccountParams());
  });

  setUp(() {
    mockGetAccounts = MockGetAssetAccountsUseCase();
    mockDeleteAccount = MockDeleteAssetAccountUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    bloc = AccountListBloc(
      getAssetAccountsUseCase: mockGetAccounts,
      deleteAssetAccountUseCase: mockDeleteAccount,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() {
    bloc.close();
    dataChangeController.close();
  });

  const tAccount = AssetAccount(
    id: '1',
    name: 'Test Account',
    type: AssetType.bank,
    initialBalance: 100,
    currentBalance: 100,
  );
  final tAccounts = [tAccount];

  group('AccountListBloc', () {
    test('initial state is AccountListInitial', () {
      expect(bloc.state, const AccountListInitial());
    });

    group('LoadAccounts', () {
      blocTest<AccountListBloc, AccountListState>(
        'emits [AccountListLoading, AccountListLoaded] when successful',
        build: () {
          when(() => mockGetAccounts(any()))
              .thenAnswer((_) async => Right(tAccounts));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAccounts()),
        expect: () => [
          const AccountListLoading(isReloading: false),
          AccountListLoaded(accounts: tAccounts),
        ],
        verify: (_) {
          verify(() => mockGetAccounts(const NoParams())).called(1);
        },
      );

      blocTest<AccountListBloc, AccountListState>(
        'emits [AccountListLoading, AccountListError] when failure',
        build: () {
          when(() => mockGetAccounts(any()))
              .thenAnswer((_) async => const Left(CacheFailure('Error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAccounts()),
        expect: () => [
          const AccountListLoading(isReloading: false),
          const AccountListError('Database Error: Error'),
        ],
      );

      blocTest<AccountListBloc, AccountListState>(
        'emits [AccountListLoading, AccountListLoaded] when forcing reload',
        seed: () => AccountListLoaded(accounts: tAccounts),
        build: () {
          when(() => mockGetAccounts(any()))
              .thenAnswer((_) async => Right(tAccounts));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAccounts(forceReload: true)),
        expect: () => [
          const AccountListLoading(isReloading: true),
          AccountListLoaded(accounts: tAccounts),
        ],
      );
    });

    group('DeleteAccountRequested', () {
      blocTest<AccountListBloc, AccountListState>(
        'emits optimistic update then success',
        seed: () => AccountListLoaded(accounts: tAccounts),
        build: () {
          when(() => mockDeleteAccount(any()))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const DeleteAccountRequested('1')),
        expect: () => [
          const AccountListLoaded(accounts: []), // Optimistic removal
        ],
        verify: (_) {
          verify(() => mockDeleteAccount(const DeleteAssetAccountParams('1')))
              .called(1);
        },
      );

      blocTest<AccountListBloc, AccountListState>(
        'emits optimistic update then reverts on failure',
        seed: () => AccountListLoaded(accounts: tAccounts),
        build: () {
          when(() => mockDeleteAccount(any()))
              .thenAnswer((_) async => const Left(CacheFailure('Fail')));
          return bloc;
        },
        act: (bloc) => bloc.add(const DeleteAccountRequested('1')),
        expect: () => [
          const AccountListLoaded(accounts: []), // Optimistic removal
          const AccountListError(
              'Failed to delete account: Database Error: Fail'),
          AccountListLoaded(accounts: tAccounts), // Revert
        ],
      );
    });

    group('DataChangedEvent', () {
      blocTest<AccountListBloc, AccountListState>(
        'reloads accounts when account data changes',
        build: () {
          when(() => mockGetAccounts(any()))
              .thenAnswer((_) async => Right(tAccounts));
          return bloc;
        },
        act: (bloc) {
          dataChangeController.add(const DataChangedEvent(
              type: DataChangeType.account, reason: DataChangeReason.updated));
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          const AccountListLoading(isReloading: false),
          AccountListLoaded(accounts: tAccounts),
        ],
      );

      blocTest<AccountListBloc, AccountListState>(
        'resets state when system reset event received',
        seed: () => AccountListLoaded(accounts: tAccounts),
        build: () {
          when(() => mockGetAccounts(any()))
              .thenAnswer((_) async => const Right(<AssetAccount>[]));
          return bloc;
        },
        act: (bloc) {
          dataChangeController.add(const DataChangedEvent(
              type: DataChangeType.system, reason: DataChangeReason.reset));
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          const AccountListInitial(),
          const AccountListLoading(isReloading: false),
          const AccountListLoaded(accounts: []),
        ],
      );
    });

    group('ResetState', () {
      blocTest<AccountListBloc, AccountListState>(
        'resets state and loads accounts',
        seed: () => AccountListLoaded(accounts: tAccounts),
        build: () {
          when(() => mockGetAccounts(any()))
              .thenAnswer((_) async => const Right(<AssetAccount>[]));
          return bloc;
        },
        act: (bloc) => bloc.add(const ResetState()),
        expect: () => [
          const AccountListInitial(),
          const AccountListLoading(isReloading: false),
          const AccountListLoaded(accounts: []),
        ],
      );
    });
  });
}
