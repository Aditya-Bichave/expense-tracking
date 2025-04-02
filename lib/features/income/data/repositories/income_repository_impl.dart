import 'package:dartz/dartz.dart';
import 'package:expense_tracker/main.dart'; // Import logger
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
    log.info("[IncomeRepo] Adding income '${income.title}'.");
    try {
      final incomeModel = IncomeModel.fromEntity(income);
      final addedModel = await localDataSource.addIncome(incomeModel);
      log.info("[IncomeRepo] Add successful. Returning entity.");
      return Right(addedModel.toEntity());
    } on CacheFailure catch (e) {
      log.warning("[IncomeRepo] CacheFailure during add: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[IncomeRepo] Unexpected error adding income$e$s");
      return Left(
          UnexpectedFailure('Unexpected error adding income: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteIncome(String id) async {
    log.info("[IncomeRepo] Deleting income (ID: $id).");
    try {
      await localDataSource.deleteIncome(id);
      log.info("[IncomeRepo] Delete successful.");
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning("[IncomeRepo] CacheFailure during delete: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[IncomeRepo] Unexpected error deleting income$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error deleting income: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Income>>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? accountId,
  }) async {
    log.info(
        "[IncomeRepo] Getting incomes. Filters: AccID=$accountId, Start=$startDate, End=$endDate, Cat=$category");
    try {
      final incomeModels = await localDataSource.getIncomes();
      List<Income> incomes =
          incomeModels.map((model) => model.toEntity()).toList();
      log.info("[IncomeRepo] Fetched and mapped ${incomes.length} incomes.");

      // Apply filtering
      final originalCount = incomes.length;
      incomes = incomes.where((inc) {
        bool dateMatch = true;
        bool categoryMatch = true;
        bool accountMatch = true;

        // Date filtering (inclusive)
        if (startDate != null) {
          final incDateOnly =
              DateTime(inc.date.year, inc.date.month, inc.date.day);
          final startDateOnly =
              DateTime(startDate.year, startDate.month, startDate.day);
          dateMatch = !incDateOnly.isBefore(startDateOnly);
        }
        if (endDate != null && dateMatch) {
          final incDateOnly =
              DateTime(inc.date.year, inc.date.month, inc.date.day);
          final endDateOnly =
              DateTime(endDate.year, endDate.month, endDate.day);
          dateMatch = !incDateOnly.isAfter(endDateOnly);
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
      log.info(
          "[IncomeRepo] Filtered incomes: ${incomes.length} remaining from $originalCount.");

      // Sort by date descending
      incomes.sort((a, b) => b.date.compareTo(a.date));
      log.info("[IncomeRepo] Sorted incomes.");

      return Right(incomes);
    } on CacheFailure catch (e) {
      log.warning("[IncomeRepo] CacheFailure getting incomes: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[IncomeRepo] Unexpected error getting incomes$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error getting incomes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Income>> updateIncome(Income income) async {
    log.info(
        "[IncomeRepo] Updating income '${income.title}' (ID: ${income.id}).");
    try {
      final incomeModel = IncomeModel.fromEntity(income);
      final updatedModel = await localDataSource.updateIncome(incomeModel);
      log.info("[IncomeRepo] Update successful. Returning entity.");
      return Right(updatedModel.toEntity());
    } on CacheFailure catch (e) {
      log.warning("[IncomeRepo] CacheFailure during update: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[IncomeRepo] Unexpected error updating income$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error updating income: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalIncomeForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate}) async {
    log.info(
        "[IncomeRepo] Getting total income for account: $accountId, Start=$startDate, End=$endDate");
    try {
      // Pass empty accountId as null to getExpenses
      final allIncomesResult = await getIncomes(
          accountId: accountId.isEmpty ? null : accountId,
          startDate: startDate,
          endDate: endDate);

      return allIncomesResult.fold(
        (failure) {
          log.warning(
              "[IncomeRepo] Failed to get incomes while calculating total: ${failure.message}");
          return Left(failure);
        },
        (incomes) {
          double total = incomes.fold(0.0, (sum, item) => sum + item.amount);
          log.info(
              "[IncomeRepo] Calculated total income for account $accountId: $total");
          return Right(total);
        },
      );
    } catch (e, s) {
      log.severe(
          "[IncomeRepo] Unexpected error calculating total income for account $accountId$e$s");
      return Left(UnexpectedFailure(
          'Failed to calculate total income: ${e.toString()}'));
    }
  }
}
