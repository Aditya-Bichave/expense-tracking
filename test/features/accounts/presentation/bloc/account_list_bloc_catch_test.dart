import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAssetAccountsUseCase extends Mock
    implements GetAssetAccountsUseCase {}

class MockDeleteAssetAccountUseCase extends Mock
    implements DeleteAssetAccountUseCase {}

void main() {
  late MockGetAssetAccountsUseCase mockGetAssetAccountsUseCase;
  late MockDeleteAssetAccountUseCase mockDeleteAssetAccountUseCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const DeleteAssetAccountParams(''));
  });

  setUp(() {
    mockGetAssetAccountsUseCase = MockGetAssetAccountsUseCase();
    mockDeleteAssetAccountUseCase = MockDeleteAssetAccountUseCase();
  });

  test(
    'AccountListBloc logs exception stack trace on unexpected _onLoadAccounts error',
    () async {
      when(
        () => mockGetAssetAccountsUseCase.call(any()),
      ).thenAnswer((_) async => throw Exception('unexpected error'));

      final bloc = AccountListBloc(
        getAssetAccountsUseCase: mockGetAssetAccountsUseCase,
        deleteAssetAccountUseCase: mockDeleteAssetAccountUseCase,
        dataChangeStream: const Stream.empty(),
      );

      bloc.add(const LoadAccounts());

      await expectLater(bloc.stream, emitsThrough(isA<AccountListError>()));

      await bloc.close();
    },
  );

  test(
    'AccountListBloc logs exception stack trace on unexpected _onDeleteAccountRequested error',
    () async {
      when(
        () => mockDeleteAssetAccountUseCase.call(any()),
      ).thenAnswer((_) async => throw Exception('delete crash'));

      final bloc = AccountListBloc(
        getAssetAccountsUseCase: mockGetAssetAccountsUseCase,
        deleteAssetAccountUseCase: mockDeleteAssetAccountUseCase,
        dataChangeStream: const Stream.empty(),
      );

      const account = AssetAccount(
        id: 'a1',
        name: 'Test',
        type: AssetType.bank,
        currentBalance: 50,
      );

      bloc.emit(const AccountListLoaded(accounts: [account]));
      bloc.add(const DeleteAccountRequested('a1'));

      await expectLater(bloc.stream, emitsThrough(isA<AccountListError>()));

      await bloc.close();
    },
  );
}
