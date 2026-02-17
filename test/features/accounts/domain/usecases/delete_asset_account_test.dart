import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

void main() {
  late DeleteAssetAccountUseCase useCase;
  late MockAssetAccountRepository mockRepository;

  setUp(() {
    mockRepository = MockAssetAccountRepository();
    useCase = DeleteAssetAccountUseCase(mockRepository);
  });

  const tAccountId = '1';

  test('should call deleteAssetAccount on repository', () async {
    // arrange
    when(
      () => mockRepository.deleteAssetAccount(tAccountId),
    ).thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(const DeleteAssetAccountParams(tAccountId));

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteAssetAccount(tAccountId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.deleteAssetAccount(tAccountId),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(const DeleteAssetAccountParams(tAccountId));

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.deleteAssetAccount(tAccountId));
  });
}
