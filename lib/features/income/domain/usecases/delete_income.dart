import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/utils/logger.dart';

class DeleteIncomeUseCase implements UseCase<void, DeleteIncomeParams> {
  final IncomeRepository repository;

  DeleteIncomeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteIncomeParams params) async {
    log.info("Executing DeleteIncomeUseCase for ID: ${params.id}.");
    return await repository.deleteIncome(params.id);
  }
}

class DeleteIncomeParams extends Equatable {
  final String id;
  const DeleteIncomeParams(this.id);
  @override
  List<Object?> get props => [id];
}
