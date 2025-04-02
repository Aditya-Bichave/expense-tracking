import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';

class AddAssetAccountUseCase
    implements UseCase<AssetAccount, AddAssetAccountParams> {
  final AssetAccountRepository repository;

  AddAssetAccountUseCase(this.repository);

  @override
  Future<Either<Failure, AssetAccount>> call(
      AddAssetAccountParams params) async {
    if (params.account.name.trim().isEmpty) {
      return Left(ValidationFailure("Account name cannot be empty."));
    }
    // Initial balance validation might happen here or in BLoC/UI
    return await repository.addAssetAccount(params.account);
  }
}

class AddAssetAccountParams extends Equatable {
  final AssetAccount account;
  const AddAssetAccountParams(this.account);
  @override
  List<Object?> get props => [account];
}
