import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
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
  late MockGetAssetAccountsUseCase mockGetAccounts;
  late MockDeleteAssetAccountUseCase mockDeleteAccount;
  late StreamController<DataChangedEvent> dataChangeController;
  late AccountListBloc bloc;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() async {
    mockGetAccounts = MockGetAssetAccountsUseCase();
    mockDeleteAccount = MockDeleteAssetAccountUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();

    await sl.reset();
    sl.registerSingleton<StreamController<DataChangedEvent>>(
      dataChangeController,
      instanceName: 'dataChangeController',
    );
    sl.registerSingleton<Stream<DataChangedEvent>>(dataChangeController.stream);

    bloc = AccountListBloc(
      getAssetAccountsUseCase: mockGetAccounts,
      deleteAssetAccountUseCase: mockDeleteAccount,
      dataChangeStream: dataChangeController.stream,
    );
  });

  tearDown(() async {
    await bloc.close();
    await dataChangeController.close();
    await sl.reset();
  });

  final tAccount = AssetAccount(
    id: '1',
    name: 'Test',
    type: AssetType.bank,
    currentBalance: 100,
  );
  final tAccounts = [tAccount];

  blocTest<AccountListBloc, AccountListState>(
    'reloads accounts when system updated DataChangedEvent is received',
    build: () {
      when(
        () => mockGetAccounts(any()),
      ).thenAnswer((_) async => Right(tAccounts));
      return bloc;
    },
    act: (bloc) {
      dataChangeController.add(
        const DataChangedEvent(
          type: DataChangeType.system,
          reason: DataChangeReason.updated,
        ),
      );
    },
    expect: () => [
      const AccountListLoading(),
      AccountListLoaded(accounts: tAccounts),
    ],
  );
}
