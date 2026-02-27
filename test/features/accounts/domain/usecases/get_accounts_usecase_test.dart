import 'package:dartz/dartz.dart';
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

  test('should call repository.getAssetAccounts', () async {
    final tAccounts = <AssetAccount>[];
    when(
      () => mockRepository.getAssetAccounts(),
    ).thenAnswer((_) async => Right(tAccounts));

    final result = await useCase(NoParams());

    expect(result, Right(tAccounts));
    verify(() => mockRepository.getAssetAccounts()).called(1);
  });
}
