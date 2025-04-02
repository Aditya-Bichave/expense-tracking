import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';

class DeleteAssetAccountUseCase
    implements UseCase<void, DeleteAssetAccountParams> {
  final AssetAccountRepository repository;

  DeleteAssetAccountUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAssetAccountParams params) async {
    // Consider adding checks here or in the repo impl if the account can be deleted
    // (e.g., check if it's the only account or has transactions)
    return await repository.deleteAssetAccount(params.id);
  }
}

class DeleteAssetAccountParams extends Equatable {
  final String id;
  const DeleteAssetAccountParams(this.id);
  @override
  List<Object?> get props => [id];
}
