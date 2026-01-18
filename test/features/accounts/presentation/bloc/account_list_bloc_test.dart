import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
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

void main() {
  late AccountListBloc bloc;
  late MockGetAssetAccountsUseCase mockGetAssetAccountsUseCase;
  late MockDeleteAssetAccountUseCase mockDeleteAssetAccountUseCase;
  late StreamController<DataChangedEvent> dataChangeController;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const DeleteAssetAccountParams(''));
  });

  setUp(() {
    mockGetAssetAccountsUseCase = MockGetAssetAccountsUseCase();
    mockDeleteAssetAccountUseCase = MockDeleteAssetAccountUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    bloc = AccountListBloc(
      getAssetAccountsUseCase: mockGetAssetAccountsUseCase,
      deleteAssetAccountUseCase: mockDeleteAssetAccountUseCase,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() {
    bloc.close();
    dataChangeController.close();
  });

  test('initial state is AccountListInitial', () {
    expect(bloc.state, isA<AccountListInitial>());
  });

  group('LoadAccounts', () {
    final tAccounts = [
      const AssetAccount(
          id: '1',
          name: 'Account 1',
          type: AssetType.cash,
          initialBalance: 100,
          currentBalance: 100),
      const AssetAccount(
          id: '2',
          name: 'Account 2',
          type: AssetType.bank,
          initialBalance: 200,
          currentBalance: 200),
    ];

    blocTest<AccountListBloc, AccountListState>(
      'emits [AccountListLoading, AccountListLoaded] when successful',
      build: () {
        when(() => mockGetAssetAccountsUseCase(any()))
            .thenAnswer((_) async => Right(tAccounts));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAccounts()),
      expect: () => [
        isA<AccountListLoading>(),
        AccountListLoaded(accounts: tAccounts),
      ],
      verify: (_) {
        verify(() => mockGetAssetAccountsUseCase(const NoParams())).called(1);
      },
    );

    blocTest<AccountListBloc, AccountListState>(
      'emits [AccountListLoading, AccountListError] when failure occurs',
      build: () {
        when(() => mockGetAssetAccountsUseCase(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAccounts()),
      expect: () => [
        isA<AccountListLoading>(),
        const AccountListError('Error'),
      ],
    );

    blocTest<AccountListBloc, AccountListState>(
      'emits [AccountListLoading, AccountListLoaded] when reloading',
      seed: () => AccountListLoaded(accounts: tAccounts),
      build: () {
        when(() => mockGetAssetAccountsUseCase(any()))
            .thenAnswer((_) async => Right(tAccounts));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAccounts(forceReload: true)),
      expect: () => [
        isA<AccountListLoading>()
            .having((s) => s.isReloading, 'isReloading', true),
        AccountListLoaded(accounts: tAccounts),
      ],
    );
  });

  group('DeleteAccountRequested', () {
    final tAccounts = [
      const AssetAccount(
          id: '1',
          name: 'Account 1',
          type: AssetType.cash,
          initialBalance: 100,
          currentBalance: 100),
      const AssetAccount(
          id: '2',
          name: 'Account 2',
          type: AssetType.bank,
          initialBalance: 200,
          currentBalance: 200),
    ];
    final tAccountsAfterDelete = [
      const AssetAccount(
          id: '2',
          name: 'Account 2',
          type: AssetType.bank,
          initialBalance: 200,
          currentBalance: 200),
    ];

    blocTest<AccountListBloc, AccountListState>(
      'performs optimistic delete and emits AccountListLoaded with item removed',
      seed: () => AccountListLoaded(accounts: tAccounts),
      build: () {
        when(() => mockDeleteAssetAccountUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteAccountRequested('1')),
      expect: () => [
        AccountListLoaded(accounts: tAccountsAfterDelete),
      ],
      verify: (_) {
        verify(() => mockDeleteAssetAccountUseCase(
            const DeleteAssetAccountParams('1'))).called(1);
      },
    );

    blocTest<AccountListBloc, AccountListState>(
      'reverts optimistic delete when deletion fails',
      seed: () => AccountListLoaded(accounts: tAccounts),
      build: () {
        when(() => mockDeleteAssetAccountUseCase(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Delete failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteAccountRequested('1')),
      expect: () => [
        AccountListLoaded(accounts: tAccountsAfterDelete), // Optimistic update
        const AccountListError(
            'Failed to delete account: Database Error: Delete failed'),
        AccountListLoaded(accounts: tAccounts), // Revert
      ],
    );
  });

  group('DataChangedEvent', () {
    final tAccounts = [
      const AssetAccount(
          id: '1',
          name: 'Account 1',
          type: AssetType.cash,
          initialBalance: 100,
          currentBalance: 100),
    ];

    blocTest<AccountListBloc, AccountListState>(
      'triggers reload when relevant DataChangedEvent is received',
      build: () {
        when(() => mockGetAssetAccountsUseCase(any()))
            .thenAnswer((_) async => Right(tAccounts));
        return bloc;
      },
      act: (bloc) async {
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.account, reason: DataChangeReason.updated));
        await Future.delayed(
            Duration.zero); // Give stream listener time to process
      },
      expect: () => [
        isA<AccountListLoading>(),
        AccountListLoaded(accounts: tAccounts),
      ],
    );

    blocTest<AccountListBloc, AccountListState>(
      'triggers ResetState when system reset event is received',
      build: () {
        when(() => mockGetAssetAccountsUseCase(any()))
            .thenAnswer((_) async => const Right(<AssetAccount>[]));
        return bloc;
      },
      act: (bloc) async {
        dataChangeController.add(const DataChangedEvent(
            type: DataChangeType.system, reason: DataChangeReason.reset));
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        isA<AccountListInitial>(),
        isA<AccountListLoading>(),
        const AccountListLoaded(accounts: <AssetAccount>[]),
      ],
    );
  });
}
