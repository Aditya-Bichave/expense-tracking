import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class AddAssetAccountUseCase
    implements UseCase<AssetAccount, AddAssetAccountParams> {
  final AssetAccountRepository repository;

  AddAssetAccountUseCase(this.repository);

  @override
  Future<Either<Failure, AssetAccount>> call(
      AddAssetAccountParams params) async {
    log.info("Executing AddAssetAccountUseCase for '${params.account.name}'.");
    if (params.account.name.trim().isEmpty) {
      log.warning("Validation failed: Account name cannot be empty.");
      return const Left(ValidationFailure("Account name cannot be empty."));
    }
    // Initial balance validation could be added here if needed (e.g., >= 0)
    // if (params.account.initialBalance < 0) {
    //   return Left(ValidationFailure("Initial balance cannot be negative."));
    // }
    return await repository.addAssetAccount(params.account);
  }
}

class AddAssetAccountParams extends Equatable {
  final AssetAccount account;
  const AddAssetAccountParams(this.account);
  @override
  List<Object?> get props => [account];
}
