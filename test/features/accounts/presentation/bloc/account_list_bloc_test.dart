import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAssetAccountsUseCase extends Mock implements GetAssetAccountsUseCase {}

class MockDeleteAssetAccountUseCase extends Mock implements DeleteAssetAccountUseCase {}

void main() {
  late MockGetAssetAccountsUseCase mockGetAssetAccountsUseCase;
  late MockDeleteAssetAccountUseCase mockDeleteAssetAccountUseCase;
  late Stream<DataChangedEvent> dataChangeStream;

  setUp(() {
    mockGetAssetAccountsUseCase = MockGetAssetAccountsUseCase();
    mockDeleteAssetAccountUseCase = MockDeleteAssetAccountUseCase();
    dataChangeStream = const Stream.empty();
    registerFallbackValue(NoParams());
    registerFallbackValue(const DeleteAssetAccountParams('1'));
  });

  final tAccount = AssetAccount(
    id: '1',
    name: 'Bank',
    initialBalance: 1000,
    currentBalance: 1000,
    type: AssetType.bank,
  );
  // AssetAccount(id: 1, name: Bank, type: AssetType.bank, initialBalance: 1000.0, currentBalance: 1000.0)
  // Constructor: const AssetAccount({required this.id, required this.name, required this.type, this.initialBalance = 0.0, required this.currentBalance});
  // It does NOT have createdAt. So remove it.

  final tAccountCorrect = AssetAccount(
    id: '1',
    name: 'Bank',
    type: AssetType.bank,
    initialBalance: 1000,
    currentBalance: 1000,
  );

  blocTest<AccountListBloc, AccountListState>(
    'emits [AccountListLoading, AccountListLoaded] when LoadAccounts succeeds',
    build: () {
      when(() => mockGetAssetAccountsUseCase(any())).thenAnswer((_) async => Right([tAccountCorrect]));
      return AccountListBloc(
        getAssetAccountsUseCase: mockGetAssetAccountsUseCase,
        deleteAssetAccountUseCase: mockDeleteAssetAccountUseCase,
        dataChangeStream: dataChangeStream,
      );
    },
    act: (bloc) => bloc.add(const LoadAccounts()),
    expect: () => [
      const AccountListLoading(isReloading: false),
      AccountListLoaded(accounts: [tAccountCorrect]),
    ],
  );

  blocTest<AccountListBloc, AccountListState>(
    'emits optimistic delete when DeleteAccountRequested',
    build: () {
      when(() => mockDeleteAssetAccountUseCase(any())).thenAnswer((_) async => const Right(null));
      return AccountListBloc(
        getAssetAccountsUseCase: mockGetAssetAccountsUseCase,
        deleteAssetAccountUseCase: mockDeleteAssetAccountUseCase,
        dataChangeStream: dataChangeStream,
      );
    },
    seed: () => AccountListLoaded(accounts: [tAccountCorrect]),
    act: (bloc) => bloc.add(const DeleteAccountRequested('1')),
    expect: () => [
      const AccountListLoaded(accounts: []), // Optimistic removal
    ],
    verify: (_) {
      verify(() => mockDeleteAssetAccountUseCase(any())).called(1);
    },
  );
}
