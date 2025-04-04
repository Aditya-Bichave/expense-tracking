import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart'; // Needed for type check and casting
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart'; // Needed for type check and casting
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart'; // Import unified entity
import 'package:expense_tracker/main.dart';

// Define Sort Options
enum TransactionSortBy { date, amount, category }

enum SortDirection { ascending, descending }

class GetTransactionsParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final String? accountId;
  final TransactionType? transactionType;
  final String? searchTerm;
  final TransactionSortBy sortBy;
  final SortDirection sortDirection;

  const GetTransactionsParams({
    this.startDate,
    this.endDate,
    this.categoryId,
    this.accountId,
    this.transactionType,
    this.searchTerm,
    this.sortBy = TransactionSortBy.date,
    this.sortDirection = SortDirection.descending,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        categoryId,
        accountId,
        transactionType,
        searchTerm,
        sortBy,
        sortDirection,
      ];
}

class GetTransactionsUseCase
    implements UseCase<List<TransactionEntity>, GetTransactionsParams> {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;

  GetTransactionsUseCase({
    required this.expenseRepository,
    required this.incomeRepository,
  });

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(
      GetTransactionsParams params) async {
    log.info(
        "[GetTransactionsUseCase] Executing. Filters: Type=${params.transactionType?.name ?? 'All'}, Acc=${params.accountId ?? 'All'}, Cat=${params.categoryId ?? 'All'}, Search='${params.searchTerm ?? ''}', Sort=${params.sortBy.name}.${params.sortDirection.name}");

    // --- Corrected approach without using .cast() on Either ---
    // Store futures that resolve to Either<Failure, List<Expense>> or Either<Failure, List<Income>>
    List<Future<Either<Failure, List<dynamic>>>> fetchFutures = [];

    if (params.transactionType == null ||
        params.transactionType == TransactionType.expense) {
      // The future itself resolves to the Either result directly
      fetchFutures.add(expenseRepository
              .getExpenses(
                startDate: params.startDate,
                endDate: params.endDate,
                category: params.categoryId,
                accountId: params.accountId,
              )
              .then((either) => either.map((list) =>
                  list as List<dynamic>)) // Map the Right side if successful
          );
    }

    if (params.transactionType == null ||
        params.transactionType == TransactionType.income) {
      fetchFutures.add(incomeRepository
              .getIncomes(
                startDate: params.startDate,
                endDate: params.endDate,
                category: params.categoryId,
                accountId: params.accountId,
              )
              .then((either) => either
                  .map((list) => list as List<dynamic>)) // Map the Right side
          );
    }
    // --- End Correction ---

    try {
      // Await all fetch operations
      final List<Either<Failure, List<dynamic>>> results =
          await Future.wait(fetchFutures);

      List<TransactionEntity> combinedList = [];
      Failure? firstFailure;

      // Process results and collect failures
      for (final result in results) {
        result.fold(
          (failure) {
            log.warning(
                "[GetTransactionsUseCase] Failed to fetch part of data: ${failure.message}");
            if (firstFailure == null) {
              firstFailure = failure; // Store the first encountered failure
            }
          },
          (list) {
            // Successfully fetched list, now map to TransactionEntity
            if (list.isNotEmpty) {
              // Check the type of the first element to determine how to map
              if (list.first is Expense) {
                combinedList.addAll(list
                    .map((e) => TransactionEntity.fromExpense(e as Expense)));
                log.fine(
                    "[GetTransactionsUseCase] Added ${list.length} expenses to combined list.");
              } else if (list.first is Income) {
                combinedList.addAll(
                    list.map((i) => TransactionEntity.fromIncome(i as Income)));
                log.fine(
                    "[GetTransactionsUseCase] Added ${list.length} incomes to combined list.");
              } else {
                log.warning(
                    "[GetTransactionsUseCase] Fetched list contains unknown type: ${list.first.runtimeType}");
              }
            } else {
              log.fine(
                  "[GetTransactionsUseCase] Fetched empty list, skipping.");
            }
          },
        );
      }

      // If any fetch operation failed, return the first failure encountered
      if (firstFailure != null) {
        log.severe(
            "[GetTransactionsUseCase] Returning failure due to partial data fetch error: ${firstFailure?.message}");
        return Left(firstFailure!);
      }

      log.info(
          "[GetTransactionsUseCase] Combined ${combinedList.length} raw transactions before filtering/sorting.");

      // Apply Search Term Filter (Client-side)
      List<TransactionEntity> filteredList = combinedList;
      if (params.searchTerm != null && params.searchTerm!.isNotEmpty) {
        final searchTermLower = params.searchTerm!.toLowerCase();
        filteredList = combinedList.where((txn) {
          // Check title, category name (if exists), and amount string
          return txn.title.toLowerCase().contains(searchTermLower) ||
              (txn.category?.name.toLowerCase().contains(searchTermLower) ??
                  false) ||
              txn.amount
                  .toStringAsFixed(2)
                  .contains(searchTermLower); // Search formatted amount string
        }).toList();
        log.info(
            "[GetTransactionsUseCase] Filtered by search '${params.searchTerm}': ${filteredList.length} items remaining.");
      }

      // Apply Sorting
      filteredList.sort((a, b) {
        int comparison;
        switch (params.sortBy) {
          case TransactionSortBy.amount:
            // Consider type for amount sorting? Maybe sort expense/income separately?
            // For now, absolute amount sort.
            comparison = a.amount.compareTo(b.amount);
            break;
          case TransactionSortBy.category:
            // Handle null categories gracefully
            comparison =
                (a.category?.name ?? 'zzzzzz') // Put uncategorized last
                    .toLowerCase()
                    .compareTo((b.category?.name ?? 'zzzzzz').toLowerCase());
            break;
          case TransactionSortBy.date:
          default:
            comparison = a.date.compareTo(b.date);
            break;
        }
        // Apply direction
        return params.sortDirection == SortDirection.ascending
            ? comparison
            : -comparison;
      });
      log.info(
          "[GetTransactionsUseCase] Sorted list. Returning ${filteredList.length} transactions.");

      return Right(filteredList); // Return the final filtered and sorted list
    } catch (e, s) {
      // Catch any unexpected errors during the process
      log.severe(
          "[GetTransactionsUseCase] Unexpected error during processing: $e\n$s");
      return Left(UnexpectedFailure(
          "An unexpected error occurred while fetching transactions: $e"));
    }
  }
}
