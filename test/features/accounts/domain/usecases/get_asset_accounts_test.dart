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

  final tAccounts = [
    const AssetAccount(
      id: '1',
      name: 'Account 1',
      type: AssetType.cash,
      initialBalance: 100,
      currentBalance: 100,
    ),
  ];

  test('should get list of asset accounts from the repository', () async {
    when(() => mockRepository.getAssetAccounts())
        .thenAnswer((_) async => Right(tAccounts));

    final result = await useCase(const NoParams());

    expect(result, Right(tAccounts));
    verify(() => mockRepository.getAssetAccounts());
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when repository fails', () async {
    when(() => mockRepository.getAssetAccounts())
        .thenAnswer((_) async => const Left(ServerFailure('Error')));

    final result = await useCase(const NoParams());

    expect(result, const Left(ServerFailure('Error')));
    verify(() => mockRepository.getAssetAccounts());
    verifyNoMoreInteractions(mockRepository);
  });
}
