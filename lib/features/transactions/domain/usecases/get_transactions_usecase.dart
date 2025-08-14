import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
// Import Models
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
// Import Repositories
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
// Import Entities
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
// Import CategorizationStatus
import 'package:expense_tracker/main.dart';

// Keep Sort Options and Params as they are
enum TransactionSortBy { date, amount, category, title } // Added title

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

    // Fetch hydrated entities directly from repositories
    List<Future<Either<Failure, List<dynamic>>>> fetchFutures = [];

    if (params.transactionType == null ||
        params.transactionType == TransactionType.expense) {
      fetchFutures.add(expenseRepository
          .getExpenses(
            startDate: params.startDate,
            endDate: params.endDate,
            categoryIds:
                params.categoryId != null ? [params.categoryId!] : null,
            accountId: params.accountId,
          )
          .then((either) => either.map((list) => list as List<dynamic>)));
    }

    if (params.transactionType == null ||
        params.transactionType == TransactionType.income) {
      fetchFutures.add(incomeRepository
          .getIncomes(
            startDate: params.startDate,
            endDate: params.endDate,
            categoryIds:
                params.categoryId != null ? [params.categoryId!] : null,
            accountId: params.accountId,
          )
          .then((either) => either.map((list) => list as List<dynamic>)));
    }

    try {
      final List<Either<Failure, List<dynamic>>> results =
          await Future.wait(fetchFutures);

      // Check for failures
      for (final result in results) {
        if (result.isLeft()) {
          final failure = result.fold((l) => l, (_) => null);
          log.warning(
              "[GetTransactionsUseCase] Failed to fetch transactions: ${failure?.message}");
          return Left(failure ??
              const CacheFailure("Failed to fetch transactions"));
        }
      }

      // Combine successful results
      List<TransactionEntity> combinedList = [];
      for (final result in results) {
        final entities = result.getOrElse(() => []);
        if (entities.isEmpty) continue;

        if (entities.first is Expense) {
          final expenses = entities.cast<Expense>();
          combinedList
              .addAll(expenses.map((e) => TransactionEntity.fromExpense(e)));
        } else if (entities.first is Income) {
          final incomes = entities.cast<Income>();
          combinedList
              .addAll(incomes.map((i) => TransactionEntity.fromIncome(i)));
        }
      }

      log.info(
          "[GetTransactionsUseCase] Combined ${combinedList.length} hydrated transactions before filtering/sorting.");

      // Apply Search Term Filter (Client-side)
      List<TransactionEntity> filteredList = combinedList;
      if (params.searchTerm != null && params.searchTerm!.isNotEmpty) {
        final searchTermLower = params.searchTerm!.toLowerCase();
        filteredList = combinedList.where((txn) {
          return txn.title.toLowerCase().contains(searchTermLower) ||
              (txn.category?.name.toLowerCase().contains(searchTermLower) ??
                  false) ||
              txn.amount.toStringAsFixed(2).contains(searchTermLower);
        }).toList();
        log.info(
            "[GetTransactionsUseCase] Filtered by search '${params.searchTerm}': ${filteredList.length} items remaining.");
      }

      // Apply Sorting
      filteredList.sort((a, b) {
        int comparison;
        switch (params.sortBy) {
          case TransactionSortBy.amount:
            comparison = a.amount.compareTo(b.amount);
            break;
          case TransactionSortBy.category:
            comparison = (a.category?.name ?? 'zzzzzz')
                .toLowerCase()
                .compareTo((b.category?.name ?? 'zzzzzz').toLowerCase());
            break;
          // --- Added Title Sort ---
          case TransactionSortBy.title:
            comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
            break;
          case TransactionSortBy.date:
            comparison = a.date.compareTo(b.date);
            break;
        }
        return params.sortDirection == SortDirection.ascending
            ? comparison
            : -comparison;
      });
      log.info(
          "[GetTransactionsUseCase] Sorted list. Returning ${filteredList.length} transactions.");

      return Right(filteredList);
    } catch (e, s) {
      log.severe(
          "[GetTransactionsUseCase] Unexpected error during processing: $e\n$s");
      return Left(UnexpectedFailure(
          "An unexpected error occurred while fetching transactions: $e"));
    }
  }
}
