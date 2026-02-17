import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

void main() {
  late UpdateAssetAccountUseCase useCase;
  late MockAssetAccountRepository mockRepository;

  setUp(() {
    mockRepository = MockAssetAccountRepository();
    useCase = UpdateAssetAccountUseCase(mockRepository);
  });

  const tAccount = AssetAccount(
    id: '1',
    name: 'Bank',
    type: AssetType.bank,
    initialBalance: 100.0,
    currentBalance: 100.0,
  );

  test('should call updateAssetAccount on repository', () async {
    // arrange
    when(
      () => mockRepository.updateAssetAccount(tAccount),
    ).thenAnswer((_) async => const Right(tAccount));

    // act
    final result = await useCase(UpdateAssetAccountParams(tAccount));

    // assert
    expect(result, const Right(tAccount)); // Expecting the account back
    verify(() => mockRepository.updateAssetAccount(tAccount));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.updateAssetAccount(tAccount),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(UpdateAssetAccountParams(tAccount));

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.updateAssetAccount(tAccount));
  });
}
