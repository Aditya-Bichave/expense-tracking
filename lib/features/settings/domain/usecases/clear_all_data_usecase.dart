import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class ClearAllDataUseCase implements UseCase<void, NoParams> {
  final DataManagementRepository dataManagementRepository;

  ClearAllDataUseCase(this.dataManagementRepository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    log.info("[ClearAllDataUseCase] Clear process started.");
    try {
      log.info("[ClearAllDataUseCase] Calling repository.clearAllData...");
      final result = await dataManagementRepository.clearAllData();
      result.fold(
        (f) => log.warning(
          "[ClearAllDataUseCase] Repository clear failed: ${f.message}",
        ),
        (_) => log.info("[ClearAllDataUseCase] Repository clear successful."),
      );
      return result;
    } catch (e, s) {
      log.severe("[ClearAllDataUseCase] Unexpected error$e$s");
      return Left(
        ClearDataFailure(
          "An unexpected error occurred while clearing data: ${e.toString()}",
        ),
      );
    }
  }
}
