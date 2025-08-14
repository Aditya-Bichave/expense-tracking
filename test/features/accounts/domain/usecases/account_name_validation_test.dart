import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

void main() {
  late MockAssetAccountRepository repository;
  late AddAssetAccountUseCase addUseCase;
  late UpdateAssetAccountUseCase updateUseCase;

  setUp(() {
    repository = MockAssetAccountRepository();
    addUseCase = AddAssetAccountUseCase(repository);
    updateUseCase = UpdateAssetAccountUseCase(repository);
  });

  const validAccount = AssetAccount(
    id: '1',
    name: 'Valid 123',
    type: AssetType.cash,
    currentBalance: 0,
  );

  const invalidAccount = AssetAccount(
    id: '1',
    name: 'Invalid@Name!',
    type: AssetType.cash,
    currentBalance: 0,
  );

  test('AddAssetAccountUseCase fails for non-alphanumeric name', () async {
    final result = await addUseCase(AddAssetAccountParams(invalidAccount));

    expect(
      result,
      equals(
          const Left(ValidationFailure('Account name must be alphanumeric.'))),
    );
    verifyZeroInteractions(repository);
  });

  test('UpdateAssetAccountUseCase fails for non-alphanumeric name', () async {
    final result = await updateUseCase(
      UpdateAssetAccountParams(invalidAccount),
    );

    expect(
      result,
      equals(
          const Left(ValidationFailure('Account name must be alphanumeric.'))),
    );
    verifyZeroInteractions(repository);
  });

  test('AddAssetAccountUseCase succeeds for valid name', () async {
    when(() => repository.addAssetAccount(validAccount))
        .thenAnswer((_) async => const Right(validAccount));

    final result = await addUseCase(AddAssetAccountParams(validAccount));

    expect(result, equals(const Right(validAccount)));
    verify(() => repository.addAssetAccount(validAccount)).called(1);
  });

  test('UpdateAssetAccountUseCase succeeds for valid name', () async {
    when(() => repository.updateAssetAccount(validAccount))
        .thenAnswer((_) async => const Right(validAccount));

    final result = await updateUseCase(
      UpdateAssetAccountParams(validAccount),
    );

    expect(result, equals(const Right(validAccount)));
    verify(() => repository.updateAssetAccount(validAccount)).called(1);
  });
}
