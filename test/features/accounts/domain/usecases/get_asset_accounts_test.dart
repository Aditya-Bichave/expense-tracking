import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

void main() {
  late GetAssetAccountsUseCase useCase;
  late MockAssetAccountRepository mockRepository;

  setUp(() {
    mockRepository = MockAssetAccountRepository();
    useCase = GetAssetAccountsUseCase(mockRepository);
  });

  const tAccounts = [
    AssetAccount(
      id: '1',
      name: 'Bank',
      type: AssetType.bank,
      initialBalance: 100.0,
      currentBalance: 100.0,
    ),
  ];

  test('should get accounts from repository', () async {
    // arrange
    when(
      () => mockRepository.getAssetAccounts(),
    ).thenAnswer((_) async => const Right(tAccounts));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result, const Right(tAccounts));
    verify(() => mockRepository.getAssetAccounts());
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.getAssetAccounts(),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.getAssetAccounts());
  });
}
