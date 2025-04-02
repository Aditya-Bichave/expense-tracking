import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  final IncomeLocalDataSource localDataSource;

  IncomeRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Income>> addIncome(Income income) async {
    debugPrint("[IncomeRepo] addIncome called for '${income.title}'.");
    try {
      final incomeModel = IncomeModel.fromEntity(income);
      debugPrint(
          "[IncomeRepo] Mapped to model. Calling localDataSource.addIncome...");
      final addedModel = await localDataSource.addIncome(incomeModel);
      debugPrint("[IncomeRepo] Added to local source. Returning Right.");
      return Right(addedModel.toEntity());
    } on CacheFailure catch (e) {
      debugPrint("[IncomeRepo] CacheFailure during add: $e");
      return Left(e);
    } catch (e, s) {
      debugPrint("[IncomeRepo] *** CRITICAL ERROR during add: $e\n$s");
      return Left(
          CacheFailure('Unexpected error adding income: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteIncome(String id) async {
    debugPrint("[IncomeRepo] deleteIncome called for ID: $id.");
    try {
      debugPrint("[IncomeRepo] Calling localDataSource.deleteIncome...");
      await localDataSource.deleteIncome(id);
      debugPrint(
          "[IncomeRepo] Deleted from local source. Returning Right(null).");
      return const Right(null);
    } on CacheFailure catch (e) {
      debugPrint("[IncomeRepo] CacheFailure during delete: $e");
      return Left(e);
    } catch (e, s) {
      debugPrint("[IncomeRepo] *** CRITICAL ERROR during delete: $e\n$s");
      return Left(
          CacheFailure('Unexpected error deleting income: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Income>>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? accountId,
  }) async {
    debugPrint(
        "[IncomeRepo] getIncomes called. Filters: AccID=$accountId, Start=$startDate, End=$endDate, Cat=$category");
    try {
      debugPrint("[IncomeRepo] Fetching income models from local source...");
      final incomeModels = await localDataSource.getIncomes();
      debugPrint("[IncomeRepo] Fetched ${incomeModels.length} income models.");

      List<Income> incomes = [];
      try {
        incomes = incomeModels.map((model) => model.toEntity()).toList();
        debugPrint("[IncomeRepo] Mapped ${incomes.length} models to entities.");
      } catch (e, s) {
        debugPrint(
            "[IncomeRepo] *** CRITICAL ERROR mapping models to entities: $e\n$s");
        return Left(
            CacheFailure("Error mapping income models: ${e.toString()}"));
      }

      // Apply filtering
      try {
        final originalCount = incomes.length;
        incomes = incomes.where((inc) {
          bool dateMatch = true;
          bool categoryMatch = true;
          bool accountMatch = true;

          // Date filtering
          if (startDate != null) {
            final incDateOnly =
                DateTime(inc.date.year, inc.date.month, inc.date.day);
            final startDateOnly =
                DateTime(startDate.year, startDate.month, startDate.day);
            dateMatch = incDateOnly.isAfter(startDateOnly) ||
                incDateOnly.isAtSameMomentAs(startDateOnly);
          }
          if (endDate != null && dateMatch) {
            final incDateOnly =
                DateTime(inc.date.year, inc.date.month, inc.date.day);
            final endDateOnly =
                DateTime(endDate.year, endDate.month, endDate.day);
            dateMatch = incDateOnly.isBefore(endDateOnly) ||
                incDateOnly.isAtSameMomentAs(endDateOnly);
          }
          // Category filtering
          if (category != null && category.isNotEmpty) {
            categoryMatch = inc.category.name == category;
          }
          // Account filtering
          if (accountId != null && accountId.isNotEmpty) {
            accountMatch = inc.accountId == accountId;
          }
          return dateMatch && categoryMatch && accountMatch;
        }).toList();
        debugPrint(
            "[IncomeRepo] Filtered incomes: ${incomes.length} remaining from $originalCount.");
      } catch (e, s) {
        debugPrint(
            "[IncomeRepo] *** CRITICAL ERROR during income filtering: $e\n$s");
        return Left(
            CacheFailure("Error applying income filters: ${e.toString()}"));
      }

      // Sort
      try {
        incomes.sort((a, b) => b.date.compareTo(a.date));
        debugPrint("[IncomeRepo] Sorted incomes.");
      } catch (e, s) {
        debugPrint(
            "[IncomeRepo] *** CRITICAL ERROR during income sorting: $e\n$s");
        return Left(CacheFailure("Error sorting income: ${e.toString()}"));
      }

      debugPrint(
          "[IncomeRepo] Returning Right with ${incomes.length} incomes.");
      return Right(incomes);
    } on CacheFailure catch (e) {
      debugPrint("[IncomeRepo] CacheFailure getting incomes: $e");
      return Left(e);
    } catch (e, s) {
      debugPrint("[IncomeRepo] *** CRITICAL ERROR getting incomes: $e\n$s");
      return Left(
          CacheFailure('Unexpected error getting incomes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Income>> updateIncome(Income income) async {
    debugPrint("[IncomeRepo] updateIncome called for '${income.title}'.");
    try {
      final incomeModel = IncomeModel.fromEntity(income);
      debugPrint(
          "[IncomeRepo] Mapped to model. Calling localDataSource.updateIncome...");
      final updatedModel = await localDataSource.updateIncome(incomeModel);
      debugPrint("[IncomeRepo] Updated local source. Returning Right.");
      return Right(updatedModel.toEntity());
    } on CacheFailure catch (e) {
      debugPrint("[IncomeRepo] CacheFailure during update: $e");
      return Left(e);
    } catch (e, s) {
      debugPrint("[IncomeRepo] *** CRITICAL ERROR during update: $e\n$s");
      return Left(
          CacheFailure('Unexpected error updating income: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalIncomeForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate}) async {
    debugPrint(
        "[IncomeRepo] getTotalIncomeForAccount called for AccID: $accountId, Start=$startDate, End=$endDate");
    try {
      final allIncomesResult = await getIncomes(
          accountId: accountId.isEmpty ? null : accountId,
          startDate: startDate,
          endDate: endDate);
      debugPrint(
          "[IncomeRepo] getTotalIncomeForAccount - getIncomes result isLeft: ${allIncomesResult.isLeft()}");

      return allIncomesResult.fold(
        (failure) {
          debugPrint(
              "[IncomeRepo] getTotalIncomeForAccount - getIncomes failed: ${failure.message}");
          return Left(failure); // Propagate failure
        },
        (incomes) {
          try {
            double total = incomes.fold(0.0, (sum, item) => sum + item.amount);
            debugPrint(
                "[IncomeRepo] getTotalIncomeForAccount - Summed ${incomes.length} incomes. Total: $total. Returning Right.");
            return Right(total);
          } catch (e, s) {
            debugPrint(
                "[IncomeRepo] *** CRITICAL ERROR calculating total income sum: $e\n$s");
            return Left(CacheFailure("Error summing income: ${e.toString()}"));
          }
        },
      );
    } catch (e, s) {
      debugPrint(
          "[IncomeRepo] *** CRITICAL ERROR in getTotalIncomeForAccount: $e\n$s");
      return Left(CacheFailure(
          'Failed to calculate total income for account: ${e.toString()}'));
    }
  }
}
