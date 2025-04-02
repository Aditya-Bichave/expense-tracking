import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class UpdateAssetAccountUseCase
    implements UseCase<AssetAccount, UpdateAssetAccountParams> {
  final AssetAccountRepository repository;

  UpdateAssetAccountUseCase(this.repository);

  @override
  Future<Either<Failure, AssetAccount>> call(
      UpdateAssetAccountParams params) async {
    log.info(
        "Executing UpdateAssetAccountUseCase for '${params.account.name}' (ID: ${params.account.id}).");
    if (params.account.name.trim().isEmpty) {
      log.warning("Validation failed: Account name cannot be empty.");
      return const Left(ValidationFailure("Account name cannot be empty."));
    }
    // Add other validations if needed (e.g., initialBalance >= 0)
    return await repository.updateAssetAccount(params.account);
  }
}

class UpdateAssetAccountParams extends Equatable {
  final AssetAccount account;
  const UpdateAssetAccountParams(this.account);
  @override
  List<Object?> get props => [account];
}
