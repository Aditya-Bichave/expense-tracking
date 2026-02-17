import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

void main() {
  late MockAssetAccountRepository repository;
  late AddAssetAccountUseCase addUseCase;
  late UpdateAssetAccountUseCase updateUseCase;

  setUpAll(() {
    registerFallbackValue(
      const AssetAccount(
        id: 'fallback',
        name: 'fallback',
        type: AssetType.cash,
        currentBalance: 0,
      ),
    );
  });

  setUp(() {
    repository = MockAssetAccountRepository();
    addUseCase = AddAssetAccountUseCase(repository);
    updateUseCase = UpdateAssetAccountUseCase(repository);
  });

  group('AddEditAccountBloc', () {
    final existingAccount = AssetAccount(
      id: '1',
      name: 'Existing',
      type: AssetType.bank,
      initialBalance: 100,
      currentBalance: 200,
    );

    blocTest<AddEditAccountBloc, AddEditAccountState>(
      'preserves current balance when editing',
      build: () {
        when(() => repository.updateAssetAccount(any())).thenAnswer(
          (invocation) async => Right(invocation.positionalArguments.first),
        );
        return AddEditAccountBloc(
          addAssetAccountUseCase: addUseCase,
          updateAssetAccountUseCase: updateUseCase,
          initialAccount: existingAccount,
        );
      },
      act: (bloc) => bloc.add(
        const SaveAccountRequested(
          name: 'Updated',
          type: AssetType.bank,
          initialBalance: 500,
          existingAccountId: '1',
        ),
      ),
      expect: () => [
        AddEditAccountState(
          status: FormStatus.submitting,
          initialAccount: existingAccount,
        ),
        AddEditAccountState(
          status: FormStatus.success,
          initialAccount: existingAccount,
        ),
      ],
      verify: (_) {
        final captured =
            verify(
                  () => repository.updateAssetAccount(captureAny()),
                ).captured.single
                as AssetAccount;
        expect(captured.currentBalance, existingAccount.currentBalance);
        expect(captured.initialBalance, 500);
      },
    );
  });
}
