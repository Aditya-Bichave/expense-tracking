import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // Import CategorizationStatus
import 'package:expense_tracker/main.dart'; // logger

enum TransactionType { expense, income }

class ApplyCategoryToBatchParams extends Equatable {
  final List<String> transactionIds;
  final String categoryId;
  final TransactionType transactionType; // To know which repository to use

  const ApplyCategoryToBatchParams({
    required this.transactionIds,
    required this.categoryId,
    required this.transactionType,
  });

  @override
  List<Object?> get props => [transactionIds, categoryId, transactionType];
}

class ApplyCategoryToBatchUseCase
    implements UseCase<void, ApplyCategoryToBatchParams> {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;

  ApplyCategoryToBatchUseCase(
      {required this.expenseRepository, required this.incomeRepository});

  @override
  Future<Either<Failure, void>> call(ApplyCategoryToBatchParams params) async {
    log.info(
        "[ApplyCategoryBatchUseCase] Executing for ${params.transactionIds.length} ${params.transactionType.name} transactions. Category ID: ${params.categoryId}");

    List<Future<Either<Failure, void>>> updateFutures = [];

    for (final txnId in params.transactionIds) {
      if (params.transactionType == TransactionType.expense) {
        // Use the specific categorization update method
        updateFutures.add(expenseRepository.updateExpenseCategorization(
            txnId,
            params.categoryId,
            CategorizationStatus
                .categorized, // Batch categorize sets status to categorized
            null // Confidence not applicable for manual batch action
            ));
      } else {
        updateFutures.add(incomeRepository.updateIncomeCategorization(
            txnId, params.categoryId, CategorizationStatus.categorized, null));
      }
    }

    try {
      log.info(
          "[ApplyCategoryBatchUseCase] Awaiting ${updateFutures.length} update futures...");
      final results = await Future.wait(updateFutures);

      // Check if any individual update failed
      List<String> failedIds = [];
      Failure? firstFailure;
      for (int i = 0; i < results.length; i++) {
        results[i].fold(
          (failure) {
            if (firstFailure == null) firstFailure = failure;
            failedIds.add(params.transactionIds[i]);
          },
          (_) {},
        );
      }

      if (firstFailure != null) {
        log.warning(
            "[ApplyCategoryBatchUseCase] Some updates failed (${failedIds.length} / ${params.transactionIds.length}). IDs: ${failedIds.join(', ')}. First error: ${firstFailure?.message}");
        // Return the first failure encountered, maybe wrap it
        return Left(CacheFailure(
            "Failed to update category for some transactions: ${firstFailure?.message}"));
      }

      log.info("[ApplyCategoryBatchUseCase] All batch updates successful.");
      return const Right(null); // Overall success
    } catch (e, s) {
      log.severe(
          "[ApplyCategoryBatchUseCase] Unexpected error during batch update$e$s");
      return Left(CacheFailure(
          "Unexpected error applying batch category: ${e.toString()}"));
    }
  }
}
