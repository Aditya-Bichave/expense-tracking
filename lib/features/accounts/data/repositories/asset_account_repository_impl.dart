import 'package:dartz/dartz.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';

class AssetAccountRepositoryImpl implements AssetAccountRepository {
  final AssetAccountLocalDataSource localDataSource;
  final IncomeRepository incomeRepository;
  final ExpenseRepository expenseRepository;

  AssetAccountRepositoryImpl({
    required this.localDataSource,
    required this.incomeRepository,
    required this.expenseRepository,
  });

  @override
  Future<Either<Failure, AssetAccount>> addAssetAccount(
    AssetAccount account,
  ) async {
    log.info("[AssetAccountRepo] Adding account '${account.name}'.");
    try {
      final accountModel = AssetAccountModel.fromEntity(account);
      log.info(
        "[AssetAccountRepo] Mapped to model. Calling localDataSource...",
      );
      await localDataSource.addAssetAccount(accountModel);
      log.info(
        "[AssetAccountRepo] Added to local source. Calculating balance...",
      );

      // Recalculate balance for the returned entity
      final balanceResult = await _calculateBalance(
        account.id,
        account.initialBalance,
      );
      log.info(
        "[AssetAccountRepo] Balance calculation result isLeft: ${balanceResult.isLeft()}.",
      );

      return balanceResult.fold(
        (failure) {
          log.warning(
            "[AssetAccountRepo] Balance calculation failed during add for '${account.name}': ${failure.message}.",
          );
          return Left(failure); // Propagate balance calculation failure
        },
        (balance) {
          log.info(
            "[AssetAccountRepo] Balance calculated ($balance) for '${account.name}'. Returning entity.",
          );
          return Right(accountModel.toEntity(balance));
        },
      );
    } on CacheFailure catch (e, s) {
      log.severe(
        "[AssetAccountRepo] CacheFailure during add for '${account.name}'$e$s",
      );
      return Left(e);
    } catch (e, s) {
      log.severe(
        "[AssetAccountRepo] Unexpected error during add for '${account.name}'$e$s",
      );
      return Left(CacheFailure('Failed to add account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AssetAccount>> updateAssetAccount(
    AssetAccount account,
  ) async {
    log.info(
      "[AssetAccountRepo] Updating account '${account.name}' (ID: ${account.id}).",
    );
    try {
      final accountModel = AssetAccountModel.fromEntity(account);
      log.info(
        "[AssetAccountRepo] Mapped to model. Calling localDataSource...",
      );
      await localDataSource.updateAssetAccount(accountModel);
      log.info(
        "[AssetAccountRepo] Updated local source. Calculating balance...",
      );
      final balanceResult = await _calculateBalance(
        account.id,
        account.initialBalance,
      );
      log.info(
        "[AssetAccountRepo] Balance calculation result isLeft: ${balanceResult.isLeft()}.",
      );

      return balanceResult.fold(
        (failure) {
          log.warning(
            "[AssetAccountRepo] Balance calculation failed during update for '${account.name}': ${failure.message}.",
          );
          return Left(failure);
        },
        (balance) {
          log.info(
            "[AssetAccountRepo] Balance calculated ($balance) for '${account.name}'. Returning entity.",
          );
          return Right(accountModel.toEntity(balance));
        },
      );
    } on CacheFailure catch (e, s) {
      log.severe(
        "[AssetAccountRepo] CacheFailure during update for '${account.name}'$e$s",
      );
      return Left(e);
    } catch (e, s) {
      log.severe(
        "[AssetAccountRepo] Unexpected error during update for '${account.name}'$e$s",
      );
      return Left(CacheFailure('Failed to update account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAssetAccount(String id) async {
    log.info("[AssetAccountRepo] Deleting account (ID: $id).");

    // **Chosen Strategy:** Prevent deletion if account has transactions.
    try {
      log.info(
        "[AssetAccountRepo] Checking for linked income/expenses for account ID: $id...",
      );
      final incomeCheck = await incomeRepository.getIncomes(accountId: id);
      final expenseCheck = await expenseRepository.getExpenses(accountId: id);

      bool hasTransactions = false;
      String transactionCheckError = '';

      incomeCheck.fold(
        (f) => transactionCheckError += "Income check failed: ${f.message}. ",
        (incomes) => hasTransactions = hasTransactions || incomes.isNotEmpty,
      );
      expenseCheck.fold(
        (f) => transactionCheckError += "Expense check failed: ${f.message}. ",
        (expenses) => hasTransactions = hasTransactions || expenses.isNotEmpty,
      );

      if (transactionCheckError.isNotEmpty) {
        log.warning(
          "[AssetAccountRepo] Error checking transactions for account $id: $transactionCheckError",
        );
        return Left(
          CacheFailure(
            "Could not verify linked transactions: $transactionCheckError",
          ),
        );
      }

      if (hasTransactions) {
        log.warning(
          "[AssetAccountRepo] Account $id has linked transactions. Preventing deletion.",
        );
        return const Left(
          ValidationFailure(
            "Cannot delete account with existing income or expenses. Reassign or delete transactions first.",
          ),
        );
      }

      // Proceed with deletion if no transactions found
      log.info(
        "[AssetAccountRepo] No linked transactions found. Calling localDataSource.deleteAssetAccount...",
      );
      await localDataSource.deleteAssetAccount(id);
      log.info(
        "[AssetAccountRepo] Deleted account $id from local source. Returning success.",
      );
      return const Right(null);
    } on CacheFailure catch (e, s) {
      log.severe(
        "[AssetAccountRepo] CacheFailure during delete for ID $id$e$s",
      );
      return Left(e);
    } catch (e, s) {
      log.severe(
        "[AssetAccountRepo] Unexpected error during delete for ID $id$e$s",
      );
      return Left(CacheFailure('Failed to delete account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AssetAccount>>> getAssetAccounts() async {
    log.info("[AssetAccountRepo] Getting all asset accounts...");
    try {
      log.info("[AssetAccountRepo] Fetching account models...");
      final accountModels = await localDataSource.getAssetAccounts();
      log.info("[AssetAccountRepo] Fetched ${accountModels.length} models.");

      // Fetch all incomes and expenses in parallel to avoid N+1 queries
      final incomesFuture = incomeRepository.getIncomes();
      final expensesFuture = expenseRepository.getExpenses();
      final incomeResult = await incomesFuture;
      final expenseResult = await expensesFuture;

      if (incomeResult.isLeft()) {
        return incomeResult.fold(
          (l) => Left(l),
          (_) => const Left(CacheFailure('Failed to fetch incomes')),
        );
      }
      if (expenseResult.isLeft()) {
        return expenseResult.fold(
          (l) => Left(l),
          (_) => const Left(CacheFailure('Failed to fetch expenses')),
        );
      }

      final incomeModels = incomeResult.getOrElse(() => []);
      final expenseModels = expenseResult.getOrElse(() => []);

      final Map<String, double> incomeMap = {};
      for (final income in incomeModels) {
        incomeMap.update(
          income.accountId,
          (value) => value + income.amount,
          ifAbsent: () => income.amount,
        );
      }

      final Map<String, double> expenseMap = {};
      for (final expense in expenseModels) {
        expenseMap.update(
          expense.accountId,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      final accounts = accountModels.map((model) {
        final totalIncome = incomeMap[model.id] ?? 0;
        final totalExpenses = expenseMap[model.id] ?? 0;
        final balance = model.initialBalance + totalIncome - totalExpenses;
        return model.toEntity(balance);
      }).toList();

      log.info(
        "[AssetAccountRepo] Finished calculating all balances in-memory. Returning ${accounts.length} accounts.",
      );
      return Right(accounts);
    } on CacheFailure catch (e, s) {
      log.severe("[AssetAccountRepo] CacheFailure getting asset accounts$e$s");
      return Left(e);
    } catch (e, s) {
      log.severe(
        "[AssetAccountRepo] Unexpected error getting asset accounts$e$s",
      );
      return Left(CacheFailure('Failed to get accounts: ${e.toString()}'));
    }
  }

  // Helper method for balance calculation - Returns Either<Failure, double>
  Future<Either<Failure, double>> _calculateBalance(
    String accountId,
    double initialBalance,
  ) async {
    log.info(
      "[$runtimeType] _calculateBalance called for accountId: $accountId, initialBalance: $initialBalance",
    );
    try {
      log.info(
        "[$runtimeType] Fetching total income for account $accountId...",
      );
      final totalIncomeEither = await incomeRepository.getTotalIncomeForAccount(
        accountId,
      ); // Empty string handled in IncomeRepo
      totalIncomeEither.fold(
        (f) => log.warning(
          "[$runtimeType] Income fetch failed for $accountId: ${f.message}",
        ),
        (r) => log.info(
          "[$runtimeType] Income fetch success for $accountId: Value=$r",
        ),
      );

      if (totalIncomeEither.isLeft()) {
        log.warning(
          "[$runtimeType] Returning Left due to income fetch failure for $accountId.",
        );
        return totalIncomeEither.fold(
          (failure) =>
              Left<Failure, double>(failure), // Extract and return Left
          (_) => const Left(
            UnexpectedFailure(
              "Impossible state: income fetch failed but fold didn't extract Failure",
            ),
          ),
        );
      }
      final totalIncome = totalIncomeEither.getOrElse(
        () => 0.0,
      ); // Safe extraction

      log.info(
        "[$runtimeType] Fetching total expenses for account $accountId...",
      );
      final totalExpensesEither = await expenseRepository
          .getTotalExpensesForAccount(
            accountId,
          ); // Empty string handled in ExpenseRepo
      totalExpensesEither.fold(
        (f) => log.warning(
          "[$runtimeType] Expense fetch failed for $accountId: ${f.message}",
        ),
        (r) => log.info(
          "[$runtimeType] Expense fetch success for $accountId: Value=$r",
        ),
      );

      if (totalExpensesEither.isLeft()) {
        log.warning(
          "[$runtimeType] Returning Left due to expense fetch failure for $accountId.",
        );
        return totalExpensesEither.fold(
          (failure) =>
              Left<Failure, double>(failure), // Extract and return Left
          (_) => const Left(
            UnexpectedFailure(
              "Impossible state: expense fetch failed but fold didn't extract Failure",
            ),
          ),
        );
      }
      final totalExpenses = totalExpensesEither.getOrElse(
        () => 0.0,
      ); // Safe extraction

      final finalBalance = initialBalance + totalIncome - totalExpenses;
      log.info(
        "[$runtimeType] Calculated balance for $accountId: $initialBalance + $totalIncome - $totalExpenses = $finalBalance. Returning Right.",
      );
      return Right(finalBalance);
    } catch (e, s) {
      log.severe(
        "[$runtimeType] CRITICAL ERROR in _calculateBalance for account $accountId$e$s",
      );
      return Left(
        CacheFailure(
          'Failed to calculate balance for account $accountId: ${e.toString()}',
        ),
      );
    }
  }
}
