import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

abstract class AssetAccountRepository {
  Future<Either<Failure, List<AssetAccount>>> getAssetAccounts();
  Future<Either<Failure, AssetAccount>> addAssetAccount(AssetAccount account);
  Future<Either<Failure, AssetAccount>> updateAssetAccount(
    AssetAccount account,
  );
  Future<Either<Failure, void>> deleteAssetAccount(String id);
  // Balance calculation is implicitly handled within the implementation (e.g., getAssetAccounts)
}
