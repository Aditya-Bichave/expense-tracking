import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
// --- END Import ---
import 'package:expense_tracker/main.dart'; // logger

// --- REMOVE the local enum definition ---
// enum TransactionType { expense, income }
// --- END REMOVE ---

class ApplyCategoryToBatchParams extends Equatable {
  final List<String> transactionIds;
  final String categoryId;
  // --- Use the imported TransactionType ---
  final TransactionType transactionType;
  // --- END Use ---

  const ApplyCategoryToBatchParams({
    required this.transactionIds,
    required this.categoryId,
    required this.transactionType, // This now refers to the primary enum
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
      // --- Use the imported TransactionType for comparison ---
      if (params.transactionType == TransactionType.expense) {
        // --- END Use ---
        // Use the specific categorization update method from the repository
        updateFutures.add(expenseRepository.updateExpenseCategorization(
            txnId,
            params.categoryId,
            CategorizationStatus
                .categorized, // Batch categorize sets status to categorized
            null // Confidence not applicable for manual batch action
            ));
      } else {
        // --- Use the imported TransactionType for comparison ---
        if (params.transactionType == TransactionType.income) {
          // --- END Use ---
          updateFutures.add(incomeRepository.updateIncomeCategorization(
              txnId,
              params.categoryId,
              CategorizationStatus
                  .categorized, // Batch categorize sets status to categorized
              null // Confidence not applicable for manual batch action
              ));
        } else {
          // Should not happen if called correctly, but good practice to handle
          log.warning(
              "[ApplyCategoryBatchUseCase] Unknown transaction type encountered for ID $txnId during batch apply.");
        }
      }
    }

    if (updateFutures.isEmpty) {
      log.info(
          "[ApplyCategoryBatchUseCase] No transactions found matching the specified type for batch update.");
      return const Right(null); // Nothing to update, consider success
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
            // Record the first failure and the ID that failed
            firstFailure ??= failure;
            // Guard against index out of bounds if transactionIds was modified unexpectedly
            if (i < params.transactionIds.length) {
              failedIds.add(params.transactionIds[i]);
            } else {
              failedIds.add("unknown_id_at_index_$i");
            }
          },
          (_) {}, // Do nothing on success
        );
      }

      if (firstFailure != null) {
        log.warning(
            "[ApplyCategoryBatchUseCase] Some updates failed (${failedIds.length} / ${params.transactionIds.length}). IDs: ${failedIds.join(', ')}. First error: ${firstFailure?.message}");
        // Return the first failure encountered, possibly wrapped in a more specific BatchFailure
        return Left(CacheFailure(
            "Failed to update category for ${failedIds.length} transaction(s): ${firstFailure?.message}"));
      }

      log.info(
          "[ApplyCategoryBatchUseCase] All ${updateFutures.length} batch updates successful.");
      return const Right(null); // Overall success
    } catch (e) {
      log.severe(
          "[ApplyCategoryBatchUseCase] Unexpected error during batch update execution");
      return Left(UnexpectedFailure(
          "Unexpected error applying batch category: ${e.toString()}"));
    }
  }
}
