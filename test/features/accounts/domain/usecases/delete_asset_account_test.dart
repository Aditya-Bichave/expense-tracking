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

  test('should delete asset account from the repository', () async {
    when(() => mockRepository.deleteAssetAccount(any()))
        .thenAnswer((_) async => const Right(null));

    final result = await useCase(const DeleteAssetAccountParams(tAccountId));

    expect(result, const Right(null));
    verify(() => mockRepository.deleteAssetAccount(tAccountId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when repository fails', () async {
    when(() => mockRepository.deleteAssetAccount(any()))
        .thenAnswer((_) async => const Left(CacheFailure('Delete failed')));

    final result = await useCase(const DeleteAssetAccountParams(tAccountId));

    expect(result, const Left(CacheFailure('Delete failed')));
    verify(() => mockRepository.deleteAssetAccount(tAccountId));
    verifyNoMoreInteractions(mockRepository);
  });
}
