// test/features/accounts/presentation/bloc/account_list/account_list_bloc_test.dart

import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockGetAssetAccountsUseCase extends Mock implements GetAssetAccountsUseCase {}
class MockDeleteAssetAccountUseCase extends Mock implements DeleteAssetAccountUseCase {}

void main() {
  group('AccountListBloc', () {
    late MockGetAssetAccountsUseCase mockGetAssetAccountsUseCase;
    late MockDeleteAssetAccountUseCase mockDeleteAssetAccountUseCase;
    late StreamController<DataChangedEvent> dataChangeController;

    setUp(() {
      mockGetAssetAccountsUseCase = MockGetAssetAccountsUseCase();
      mockDeleteAssetAccountUseCase = MockDeleteAssetAccountUseCase();
      dataChangeController = StreamController<DataChangedEvent>.broadcast();

      // Mock the default behavior for get accounts
      when(() => mockGetAssetAccountsUseCase.call(any()))
          .thenAnswer((_) async => const Right([]));
    });

    tearDown(() {
      dataChangeController.close();
    });

    test('initial state is AccountListInitial', () {
      expect(
        AccountListBloc(
          getAssetAccountsUseCase: mockGetAssetAccountsUseCase,
          deleteAssetAccountUseCase: mockDeleteAssetAccountUseCase,
          dataChangeStream: dataChangeController.stream,
        ).state,
        const AccountListInitial(),
      );
    });

    blocTest<AccountListBloc, AccountListState>(
      'emits [AccountListLoading, AccountListLoaded] when LoadAccounts is added.',
      build: () {
        when(() => mockGetAssetAccountsUseCase.call(any()))
            .thenAnswer((_) async => const Right([AssetAccount(id: '1', name: 'Test Account', balance: 100, color: 0, icon: 'icon')]));
        return AccountListBloc(
          getAssetAccountsUseCase: mockGetAssetAccountsUseCase,
          deleteAssetAccountUseCase: mockDeleteAssetAccountUseCase,
          dataChangeStream: dataChangeController.stream,
        );
      },
      act: (bloc) => bloc.add(const LoadAccounts()),
      expect: () => [
        isA<AccountListLoading>(),
        isA<AccountListLoaded>(),
      ],
      verify: (_) {
        verify(() => mockGetAssetAccountsUseCase.call(any())).called(1);
      },
    );

    // This is the key test for the fix
    blocTest<AccountListBloc, AccountListState>(
      'processes LoadAccounts only once when multiple DataChangedEvents are fired rapidly',
      build: () {
        when(() => mockGetAssetAccountsUseCase.call(any()))
            .thenAnswer((_) async {
              // Add a small delay to simulate a network call
              await Future.delayed(const Duration(milliseconds: 100));
              return const Right([AssetAccount(id: '1', name: 'Test Account', balance: 100, color: 0, icon: 'icon')]);
            });
        return AccountListBloc(
          getAssetAccountsUseCase: mockGetAssetAccountsUseCase,
          deleteAssetAccountUseCase: mockDeleteAssetAccountUseCase,
          dataChangeStream: dataChangeController.stream,
        );
      },
      act: (bloc) async {
        // Fire multiple events in quick succession
        dataChangeController.add(const DataChangedEvent(type: DataChangeType.account, reason: DataChangeReason.created));
        dataChangeController.add(const DataChangedEvent(type: DataChangeType.account, reason: DataChangeReason.updated));
        dataChangeController.add(const DataChangedEvent(type: DataChangeType.account, reason: DataChangeReason.deleted));
        // Allow time for events to be processed
        await Future.delayed(const Duration(milliseconds: 500));
      },
      verify: (_) {
        // Due to the restartable() transformer, the use case should only be called once for the last event.
        verify(() => mockGetAssetAccountsUseCase.call(any())).called(1);
      },
    );
  });
}
