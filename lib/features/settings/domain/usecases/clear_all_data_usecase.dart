import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

// Failure specific to clear process (optional)
class ClearDataFailure extends Failure {
  const ClearDataFailure(String message) : super(message);
}

class ClearAllDataUseCase implements UseCase<void, NoParams> {
  final DataManagementRepository dataManagementRepository;

  ClearAllDataUseCase(this.dataManagementRepository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    debugPrint("[ClearAllDataUseCase] Clear process started.");
    try {
      debugPrint("[ClearAllDataUseCase] Calling repository.clearAllData...");
      final result = await dataManagementRepository.clearAllData();
      debugPrint(
          "[ClearAllDataUseCase] Repository call finished. isLeft: ${result.isLeft()}");
      return result;
    } catch (e, s) {
      debugPrint("[ClearAllDataUseCase] Unexpected error: $e\n$s");
      return Left(ClearDataFailure(
          "An unexpected error occurred while clearing data: ${e.toString()}"));
    }
  }
}
