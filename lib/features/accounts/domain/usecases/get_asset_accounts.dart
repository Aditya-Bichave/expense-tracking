import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';

class GetAssetAccountsUseCase implements UseCase<List<AssetAccount>, NoParams> {
  final AssetAccountRepository repository;

  GetAssetAccountsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AssetAccount>>> call(NoParams params) async {
    debugPrint("[GetAssetAccountsUseCase] Call method executing.");
    try {
      final result = await repository.getAssetAccounts();
      debugPrint(
          "[GetAssetAccountsUseCase] Repository returned. Result isLeft: ${result.isLeft()}");
      return result;
    } catch (e, s) {
      debugPrint("[GetAssetAccountsUseCase] *** CRITICAL ERROR: $e\n$s");
      return Left(CacheFailure(
          "Unexpected error in GetAssetAccountsUseCase: $e")); // Use base Failure or a specific one
    }
  }
}
