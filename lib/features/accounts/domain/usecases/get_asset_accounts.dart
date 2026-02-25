import 'package:dartz/dartz.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class GetAssetAccountsUseCase implements UseCase<List<AssetAccount>, NoParams> {
  final AssetAccountRepository repository;

  GetAssetAccountsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AssetAccount>>> call(NoParams params) async {
    log.info("Executing GetAssetAccountsUseCase.");
    try {
      final result = await repository.getAssetAccounts();
      log.info(
        "[GetAssetAccountsUseCase] Repository returned. Result isLeft: ${result.isLeft()}",
      );
      result.fold(
        (failure) =>
            log.warning("[GetAssetAccountsUseCase] Failed: ${failure.message}"),
        (accounts) => log.info(
          "[GetAssetAccountsUseCase] Succeeded with ${accounts.length} accounts.",
        ),
      );
      return result;
    } catch (e, s) {
      log.severe("[GetAssetAccountsUseCase] Unexpected error$e$s");
      return Left(UnexpectedFailure("Unexpected error getting accounts: $e"));
    }
  }
}
