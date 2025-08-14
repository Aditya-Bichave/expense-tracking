import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
// Import Models
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
// Import Repositories
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart'; // Import Category Repo
// Import Entities
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart'; // Import Category Entity
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
  // --- Inject Category Repository ---
  final CategoryRepository categoryRepository;

  GetTransactionsUseCase({
    required this.expenseRepository,
    required this.incomeRepository,
    required this.categoryRepository, // Add to constructor
  });

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(
    GetTransactionsParams params,
  ) async {
    log.info(
      "[GetTransactionsUseCase] Executing. Filters: Type=${params.transactionType?.name ?? 'All'}, Acc=${params.accountId ?? 'All'}, Cat=${params.categoryId ?? 'All'}, Search='${params.searchTerm ?? ''}', Sort=${params.sortBy.name}.${params.sortDirection.name}",
    );

    // --- Fetch Models and Categories Concurrently ---
    List<Future<Either<Failure, List<dynamic>>>> fetchFutures = [];
    Future<Either<Failure, List<Category>>>? categoriesFuture;

    // Fetch categories required for hydration
    categoriesFuture = categoryRepository.getAllCategories();

    // Fetch expense models if needed
    if (params.transactionType == null ||
        params.transactionType == TransactionType.expense) {
      fetchFutures.add(
        expenseRepository
            .getExpenses(
              startDate: params.startDate,
              endDate: params.endDate,
              categoryId: params.categoryId,
              accountId: params.accountId,
            )
            .then((either) => either.map((list) => list as List<dynamic>)),
      );
    }

    // Fetch income models if needed
    if (params.transactionType == null ||
        params.transactionType == TransactionType.income) {
      fetchFutures.add(
        incomeRepository
            .getIncomes(
              startDate: params.startDate,
              endDate: params.endDate,
              categoryId: params.categoryId,
              accountId: params.accountId,
            )
            .then((either) => either.map((list) => list as List<dynamic>)),
      );
    }
    // --- End Fetch ---

    try {
      // Await all fetches
      final List<Either<Failure, List<dynamic>>> modelResults =
          await Future.wait(fetchFutures);
      final Either<Failure, List<Category>> categoryResult =
          await categoriesFuture;

      // --- Check for Failures ---
      Failure? firstFailure;
      if (categoryResult.isLeft()) {
        firstFailure = categoryResult.fold((l) => l, (_) => null);
        log.severe(
          "[GetTransactionsUseCase] Failed to fetch categories: ${firstFailure?.message}",
        );
        return Left(
          firstFailure ?? const CacheFailure("Failed to fetch categories"),
        );
      }
      for (final result in modelResults) {
        if (result.isLeft()) {
          firstFailure = result.fold((l) => l, (_) => null);
          log.warning(
            "[GetTransactionsUseCase] Failed to fetch transaction models: ${firstFailure?.message}",
          );
          return Left(
            firstFailure ?? const CacheFailure("Failed to fetch transactions"),
          );
        }
      }
      // --- End Failure Check ---

      // --- Process Successful Results ---
      final List<Category> allCategories = categoryResult.getOrElse(() => []);
      final categoryMap = {
        for (var cat in allCategories) cat.id: cat,
      }; // Create lookup map
      log.fine(
        "[GetTransactionsUseCase] Category map created with ${categoryMap.length} entries.",
      );

      List<TransactionEntity> combinedList = [];

      for (final result in modelResults) {
        final models = result.getOrElse(() => []); // Should always succeed here
        if (models.isEmpty) continue;

        // --- Hydration Logic Moved Here ---
        if (models.first is ExpenseModel) {
          final expenseModels = models.cast<ExpenseModel>();
          for (final model in expenseModels) {
            final category = categoryMap[model.categoryId];
            if (model.categoryId != null && category == null) {
              log.warning(
                "[GetTransactionsUseCase] Hydration warning: Category ID '${model.categoryId}' not found for expense ${model.id}.",
              );
            }
            combinedList.add(
              TransactionEntity.fromExpense(
                model.toEntity().copyWith(
                  categoryOrNull: () => category,
                ), // Hydrate here
              ),
            );
          }
          log.fine(
            "[GetTransactionsUseCase] Hydrated and added ${expenseModels.length} expenses.",
          );
        } else if (models.first is IncomeModel) {
          final incomeModels = models.cast<IncomeModel>();
          for (final model in incomeModels) {
            final category = categoryMap[model.categoryId];
            if (model.categoryId != null && category == null) {
              log.warning(
                "[GetTransactionsUseCase] Hydration warning: Category ID '${model.categoryId}' not found for income ${model.id}.",
              );
            }
            combinedList.add(
              TransactionEntity.fromIncome(
                model.toEntity().copyWith(
                  categoryOrNull: () => category,
                ), // Hydrate here
              ),
            );
          }
          log.fine(
            "[GetTransactionsUseCase] Hydrated and added ${incomeModels.length} incomes.",
          );
        }
        // --- End Hydration ---
      }

      log.info(
        "[GetTransactionsUseCase] Combined ${combinedList.length} hydrated transactions before filtering/sorting.",
      );

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
          "[GetTransactionsUseCase] Filtered by search '${params.searchTerm}': ${filteredList.length} items remaining.",
        );
      }

      // Apply Sorting
      filteredList.sort((a, b) {
        int comparison;
        switch (params.sortBy) {
          case TransactionSortBy.amount:
            comparison = a.amount.compareTo(b.amount);
            break;
          case TransactionSortBy.category:
            comparison = (a.category?.name ?? 'zzzzzz').toLowerCase().compareTo(
              (b.category?.name ?? 'zzzzzz').toLowerCase(),
            );
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
        "[GetTransactionsUseCase] Sorted list. Returning ${filteredList.length} transactions.",
      );

      return Right(filteredList);
    } catch (e, s) {
      log.severe(
        "[GetTransactionsUseCase] Unexpected error during processing: $e\n$s",
      );
      return Left(
        UnexpectedFailure(
          "An unexpected error occurred while fetching transactions: $e",
        ),
      );
    }
  }
}
