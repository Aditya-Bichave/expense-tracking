import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';

class UpdateAssetAccountUseCase
    implements UseCase<AssetAccount, UpdateAssetAccountParams> {
  final AssetAccountRepository repository;

  UpdateAssetAccountUseCase(this.repository);

  @override
  Future<Either<Failure, AssetAccount>> call(
      UpdateAssetAccountParams params) async {
    if (params.account.name.trim().isEmpty) {
      return Left(ValidationFailure("Account name cannot be empty."));
    }
    return await repository.updateAssetAccount(params.account);
  }
}

class UpdateAssetAccountParams extends Equatable {
  final AssetAccount account;
  const UpdateAssetAccountParams(this.account);
  @override
  List<Object?> get props => [account];
}
