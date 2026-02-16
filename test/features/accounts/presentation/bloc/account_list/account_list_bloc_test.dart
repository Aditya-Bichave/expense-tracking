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

void main() {
  late AccountListBloc bloc;
  late MockGetAssetAccountsUseCase mockGetAssetAccountsUseCase;
  late MockDeleteAssetAccountUseCase mockDeleteAssetAccountUseCase;
  late StreamController<DataChangedEvent> dataChangeController;

  final tAccount = AssetAccount(
    id: '1',
    name: 'Test Account',
    type: AssetType.cash,
    initialBalance: 100,
    currentBalance: 100,
  );
  final tAccounts = [tAccount];

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

  test('initial state should be AccountListInitial', () {
    expect(bloc.state, isA<AccountListInitial>());
  });

  group('LoadAccounts', () {
    blocTest<AccountListBloc, AccountListState>(
      'emits [AccountListLoading, AccountListLoaded] when successful',
      build: () {
        when(
          () => mockGetAssetAccountsUseCase(any()),
        ).thenAnswer((_) async => Right(tAccounts));
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
      'emits [AccountListLoading, AccountListError] when failure',
      build: () {
        when(
          () => mockGetAssetAccountsUseCase(any()),
        ).thenAnswer((_) async => Left(CacheFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAccounts()),
      expect: () => [
        isA<AccountListLoading>(),
        isA<AccountListError>().having(
          (s) => s.message,
          'message',
          contains('Error'),
        ),
      ],
    );
  });

  group('DeleteAccountRequested', () {
    blocTest<AccountListBloc, AccountListState>(
      'emits optimistic update then nothing if success',
      seed: () => AccountListLoaded(accounts: tAccounts),
      build: () {
        when(
          () => mockDeleteAssetAccountUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(DeleteAccountRequested(tAccount.id)),
      expect: () => [
        // Optimistic update: empty list
        AccountListLoaded(accounts: const []),
      ],
      verify: (_) {
        verify(
          () => mockDeleteAssetAccountUseCase(
            DeleteAssetAccountParams(tAccount.id),
          ),
        ).called(1);
      },
    );

    blocTest<AccountListBloc, AccountListState>(
      'emits optimistic update then reverts if failure',
      seed: () => AccountListLoaded(accounts: tAccounts),
      build: () {
        when(
          () => mockDeleteAssetAccountUseCase(any()),
        ).thenAnswer((_) async => Left(CacheFailure('Delete Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(DeleteAccountRequested(tAccount.id)),
      expect: () => [
        AccountListLoaded(accounts: const []), // Optimistic
        isA<AccountListError>().having(
          (s) => s.message,
          'message',
          contains('Delete Error'),
        ), // Error
        AccountListLoaded(accounts: tAccounts), // Revert
      ],
    );
  });

  group('DataChangedEvent', () {
    blocTest<AccountListBloc, AccountListState>(
      'triggers reload when relevant data changes',
      build: () {
        when(
          () => mockGetAssetAccountsUseCase(any()),
        ).thenAnswer((_) async => Right(tAccounts));
        return bloc;
      },
      act: (bloc) async {
        dataChangeController.add(
          const DataChangedEvent(
            type: DataChangeType.account,
            reason: DataChangeReason.updated,
          ),
        );
        // Wait for debounce/processing if any? No debounce in logic shown
      },
      expect: () => [
        isA<AccountListLoading>(),
        AccountListLoaded(accounts: tAccounts),
      ],
    );

    blocTest<AccountListBloc, AccountListState>(
      'resets state when system reset event occurs',
      build: () {
        when(
          () => mockGetAssetAccountsUseCase(any()),
        ).thenAnswer((_) async => Right(tAccounts));
        return bloc;
      },
      act: (bloc) async {
        dataChangeController.add(
          const DataChangedEvent(
            type: DataChangeType.system,
            reason: DataChangeReason.reset,
          ),
        );
      },
      expect: () => [
        isA<AccountListInitial>(),
        isA<AccountListLoading>(),
        AccountListLoaded(accounts: tAccounts),
      ],
    );
  });
}
