import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
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
      AssetAccount account) async {
    debugPrint(
        "[AssetAccountRepo] addAssetAccount called for '${account.name}'.");
    try {
      final accountModel = AssetAccountModel.fromEntity(account);
      debugPrint(
          "[AssetAccountRepo] Mapped to model. Calling localDataSource.addAssetAccount...");
      await localDataSource.addAssetAccount(accountModel);
      debugPrint(
          "[AssetAccountRepo] Added to local source. Calculating balance...");
      // Recalculate balance for the returned entity
      final balanceResult =
          await _calculateBalance(account.id, account.initialBalance);
      debugPrint(
          "[AssetAccountRepo] Balance calculation result isLeft: ${balanceResult.isLeft()}.");

      // Handle potential failure during balance calculation
      return balanceResult.fold(
        (failure) {
          debugPrint(
              "[AssetAccountRepo] Balance calculation failed during add: ${failure.message}. Returning Left.");
          return Left(failure); // Propagate balance calculation failure
        },
        (balance) {
          debugPrint(
              "[AssetAccountRepo] Balance calculated: $balance. Returning Right.");
          return Right(accountModel.toEntity(balance));
        },
      );
    } on CacheFailure catch (e) {
      debugPrint("[AssetAccountRepo] CacheFailure during add: $e");
      return Left(e);
    } catch (e, s) {
      debugPrint("[AssetAccountRepo] *** CRITICAL ERROR during add: $e\n$s");
      return Left(CacheFailure('Failed to add account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AssetAccount>> updateAssetAccount(
      AssetAccount account) async {
    debugPrint(
        "[AssetAccountRepo] updateAssetAccount called for '${account.name}'.");
    try {
      final accountModel = AssetAccountModel.fromEntity(account);
      debugPrint(
          "[AssetAccountRepo] Mapped to model. Calling localDataSource.updateAssetAccount...");
      await localDataSource.updateAssetAccount(accountModel);
      debugPrint(
          "[AssetAccountRepo] Updated local source. Calculating balance...");
      final balanceResult =
          await _calculateBalance(account.id, account.initialBalance);
      debugPrint(
          "[AssetAccountRepo] Balance calculation result isLeft: ${balanceResult.isLeft()}.");

      return balanceResult.fold(
        (failure) {
          debugPrint(
              "[AssetAccountRepo] Balance calculation failed during update: ${failure.message}. Returning Left.");
          return Left(failure);
        },
        (balance) {
          debugPrint(
              "[AssetAccountRepo] Balance calculated: $balance. Returning Right.");
          return Right(accountModel.toEntity(balance));
        },
      );
    } on CacheFailure catch (e) {
      debugPrint("[AssetAccountRepo] CacheFailure during update: $e");
      return Left(e);
    } catch (e, s) {
      debugPrint("[AssetAccountRepo] *** CRITICAL ERROR during update: $e\n$s");
      return Left(CacheFailure('Failed to update account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAssetAccount(String id) async {
    debugPrint("[AssetAccountRepo] deleteAssetAccount called for ID: $id.");
    try {
      // TODO: Decide how to handle existing income/expenses linked to this account!
      // Consider:
      // 1. Prevent deletion if linked transactions exist.
      // 2. Mark account as inactive instead of deleting.
      // 3. Reassign transactions to a default/uncategorized account.
      // 4. Delete linked transactions (potentially dangerous).
      debugPrint(
          "[AssetAccountRepo] Calling localDataSource.deleteAssetAccount...");
      await localDataSource.deleteAssetAccount(id);
      debugPrint(
          "[AssetAccountRepo] Deleted from local source. Returning Right(null).");
      return const Right(null);
    } on CacheFailure catch (e) {
      debugPrint("[AssetAccountRepo] CacheFailure during delete: $e");
      return Left(e);
    } catch (e, s) {
      debugPrint("[AssetAccountRepo] *** CRITICAL ERROR during delete: $e\n$s");
      return Left(CacheFailure('Failed to delete account: ${e.toString()}'));
    }
  }

  /* // --- !!! SIMPLIFIED VERSION FOR DEBUGGING (Commented out) !!! ---
  @override
  Future<Either<Failure, List<AssetAccount>>> getAssetAccounts() async {
    debugPrint("[AssetAccountRepo] getAssetAccounts called (Simplified Version).");
    try {
      debugPrint("[AssetAccountRepo] Fetching account models (Simplified)...");
      final accountModels = await localDataSource.getAssetAccounts();
      debugPrint("[AssetAccountRepo] Fetched ${accountModels.length} models (Simplified).");
      final List<AssetAccount> accounts = accountModels.map((model) {
        // Use initialBalance directly, skipping complex calculation for now
        return model.toEntity(model.initialBalance);
      }).toList();
      debugPrint("[AssetAccountRepo] Mapped models to entities (Simplified). Returning Right.");
      return Right(accounts);
    } on CacheFailure catch (e) {
      debugPrint("[AssetAccountRepo] CacheFailure (Simplified): $e");
      return Left(e);
    } catch (e, s) {
      debugPrint("[AssetAccountRepo] Unexpected Error (Simplified): $e\n$s");
      return Left(CacheFailure('Failed to get accounts (simplified): ${e.toString()}'));
    }
  }
  */ // --- !!! END OF SIMPLIFIED VERSION !!! ---

  // --- !!! ORIGINAL VERSION WITH LOGGING (Now Active) !!! ---
  @override
  Future<Either<Failure, List<AssetAccount>>> getAssetAccounts() async {
    debugPrint(
        "[AssetAccountRepo] getAssetAccounts called (Original Version with Logging).");
    try {
      debugPrint("[AssetAccountRepo] Fetching account models...");
      final accountModels = await localDataSource.getAssetAccounts();
      debugPrint("[AssetAccountRepo] Fetched ${accountModels.length} models.");
      final List<AssetAccount> accounts = [];

      for (int i = 0; i < accountModels.length; i++) {
        final model = accountModels[i];
        debugPrint(
            "[AssetAccountRepo] Processing account ${i + 1}/${accountModels.length}: ${model.name} (ID: ${model.id})");
        debugPrint(
            "[AssetAccountRepo] Calling _calculateBalance for ${model.name}...");
        final balanceResult =
            await _calculateBalance(model.id, model.initialBalance);
        debugPrint(
            "[AssetAccountRepo] Balance result for ${model.name}: isLeft=${balanceResult.isLeft()}");

        if (balanceResult.isLeft()) {
          debugPrint(
              "[AssetAccountRepo] Balance calculation failed for ${model.name}. Propagating failure.");
          // Propagate the specific failure from _calculateBalance
          return balanceResult.fold(
            (failure) => Left(failure),
            // This fallback should not be reached if isLeft() is true
            (_) => Left(CacheFailure(
                'Unexpected state: _calculateBalance returned Left but fold failed for ${model.name}.')),
          );
        }

        // Balance calculation succeeded, get the value and add the entity
        final calculatedBalance = balanceResult.getOrElse(() {
          // This should ideally not happen if isLeft() check passes, but good fallback
          debugPrint(
              "[AssetAccountRepo] *** WARNING: balanceResult was Right but getOrElse fallback triggered for ${model.name}. Using initialBalance.");
          return model.initialBalance;
        });
        accounts.add(model.toEntity(calculatedBalance));
        debugPrint(
            "[AssetAccountRepo] Added account ${model.name} with balance $calculatedBalance to list.");
      }
      debugPrint(
          "[AssetAccountRepo] Finished calculating all balances. Returning Right with ${accounts.length} accounts.");
      return Right(accounts);
    } on CacheFailure catch (e) {
      debugPrint("[AssetAccountRepo] CacheFailure getting asset accounts: $e");
      return Left(e);
    } catch (e, s) {
      debugPrint(
          "[AssetAccountRepo] *** CRITICAL ERROR getting asset accounts: $e\n$s");
      return Left(CacheFailure('Failed to get accounts: ${e.toString()}'));
    }
  }
  // --- !!! END OF ORIGINAL VERSION !!! ---

  // Helper method for balance calculation - Returns Either<Failure, double>
  Future<Either<Failure, double>> _calculateBalance(
      String accountId, double initialBalance) async {
    debugPrint(
        "[$runtimeType] _calculateBalance called for accountId: $accountId, initialBalance: $initialBalance");
    try {
      debugPrint(
          "[$runtimeType] Fetching total income for account $accountId...");
      // Pass empty string to get *all* income if accountId is empty, otherwise pass the ID
      final totalIncomeEither = await incomeRepository
          .getTotalIncomeForAccount(accountId.isEmpty ? '' : accountId);
      // Log failure details if Left
      totalIncomeEither.fold(
          (f) => debugPrint(
              "[$runtimeType] Income fetch failed for $accountId: ${f.message}"),
          (r) => debugPrint(
              "[$runtimeType] Income fetch success for $accountId: Value=$r"));

      if (totalIncomeEither.isLeft()) {
        debugPrint(
            "[$runtimeType] Returning Left due to income fetch failure for $accountId.");
        // FIXED: Extract the Failure and return Left<Failure, double>
        return totalIncomeEither.fold(
          (failure) => Left<Failure, double>(failure),
          // This path is impossible due to the isLeft() check
          (_) => throw StateError("Impossible state: isLeft check failed"),
        );
      }
      // Use getOrElse as a safe way to extract the value, though isLeft check passed
      final totalIncome = totalIncomeEither.getOrElse(() => 0.0);

      debugPrint(
          "[$runtimeType] Fetching total expenses for account $accountId...");
      // Pass empty string to get *all* expenses if accountId is empty, otherwise pass the ID
      final totalExpensesEither = await expenseRepository
          .getTotalExpensesForAccount(accountId.isEmpty ? '' : accountId);
      // Log failure details if Left
      totalExpensesEither.fold(
          (f) => debugPrint(
              "[$runtimeType] Expense fetch failed for $accountId: ${f.message}"),
          (r) => debugPrint(
              "[$runtimeType] Expense fetch success for $accountId: Value=$r"));

      if (totalExpensesEither.isLeft()) {
        debugPrint(
            "[$runtimeType] Returning Left due to expense fetch failure for $accountId.");
        // FIXED: Extract the Failure and return Left<Failure, double>
        return totalExpensesEither.fold(
          (failure) => Left<Failure, double>(failure),
          // This path is impossible due to the isLeft() check
          (_) => throw StateError("Impossible state: isLeft check failed"),
        );
      }
      // Use getOrElse as a safe way to extract the value
      final totalExpenses = totalExpensesEither.getOrElse(() => 0.0);

      final finalBalance = initialBalance + totalIncome - totalExpenses;
      debugPrint(
          "[$runtimeType] Calculated balance for $accountId: $initialBalance + $totalIncome - $totalExpenses = $finalBalance. Returning Right.");
      return Right(finalBalance);
    } catch (e, s) {
      // Catch any other unexpected errors during the calculation process
      debugPrint(
          "[$runtimeType] *** CRITICAL ERROR in _calculateBalance for account $accountId: $e\n$s");
      return Left(CacheFailure(
          'Failed to calculate balance for account $accountId: ${e.toString()}'));
    }
  }
}
