import 'package:dartz/dartz.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/di/service_locator.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  final IncomeLocalDataSource localDataSource;
  CategoryRepository get categoryRepository => sl<CategoryRepository>();

  IncomeRepositoryImpl({required this.localDataSource});

  // --- REMOVED _hydrateCategories helper ---

  // Helper specifically for hydrating a single model after add/update
  Future<Either<Failure, Income>> _hydrateSingleModel(IncomeModel model) async {
    final catResult =
        await categoryRepository.getCategoryById(model.categoryId ?? '');
    return catResult.fold((failure) {
      log.warning(
          "[IncomeRepo._hydrateSingleModel] Failed category lookup for ${model.id}: ${failure.message}");
      return Right(model.toEntity().copyWith(categoryOrNull: () => null));
    }, (category) {
      if (model.categoryId != null && category == null) {
        log.warning(
            "[IncomeRepo._hydrateSingleModel] Category ID '${model.categoryId}' not found for income ${model.id}.");
      }
      return Right(model.toEntity().copyWith(categoryOrNull: () => category));
    });
  }

  @override
  Future<Either<Failure, Income>> addIncome(Income income) async {
    log.info("[IncomeRepo] Adding income '${income.title}'.");
    try {
      final incomeModel = IncomeModel.fromEntity(income);
      final addedModel = await localDataSource.addIncome(incomeModel);
      log.info(
          "[IncomeRepo] Add successful (ID: ${addedModel.id}). Hydrating category.");
      return await _hydrateSingleModel(addedModel);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e, s) {
      log.severe("[IncomeRepo] Unexpected error adding income$e$s");
      return Left(
          UnexpectedFailure('Unexpected error adding income: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Income>> updateIncome(Income income) async {
    log.info(
        "[IncomeRepo] Updating income '${income.title}' (ID: ${income.id}).");
    try {
      final incomeModel = IncomeModel.fromEntity(income);
      final updatedModel = await localDataSource.updateIncome(incomeModel);
      log.info(
          "[IncomeRepo] Update successful (ID: ${updatedModel.id}). Hydrating category.");
      return await _hydrateSingleModel(updatedModel);
    } on CacheFailure catch (e) {
      log.warning("[IncomeRepo] CacheFailure during update: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[IncomeRepo] Unexpected error updating income$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error updating income: ${e.toString()}'));
    }
  }

  // --- MODIFIED getIncomes ---
  @override
  Future<Either<Failure, List<IncomeModel>>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Category ID
    String? accountId,
  }) async {
    log.info(
        "[IncomeRepo] Getting income models. Filters: AccID=$accountId, Start=$startDate, End=$endDate, CatID=$category");
    try {
      final incomeModels = await localDataSource.getIncomes();
      log.fine(
          "[IncomeRepo] Fetched ${incomeModels.length} raw income models.");

      // Apply filtering
      final filteredModels = incomeModels.where((model) {
        bool dateMatch = true;
        bool categoryMatch = true;
        bool accountMatch = true;
        if (startDate != null) {
          final incDateOnly =
              DateTime(model.date.year, model.date.month, model.date.day);
          final startDateOnly =
              DateTime(startDate.year, startDate.month, startDate.day);
          dateMatch = !incDateOnly.isBefore(startDateOnly);
        }
        if (endDate != null && dateMatch) {
          final incDateOnly =
              DateTime(model.date.year, model.date.month, model.date.day);
          final endDateOnly =
              DateTime(endDate.year, endDate.month, endDate.day);
          dateMatch = !incDateOnly.isAfter(endDateOnly);
        }
        if (accountId != null && accountId.isNotEmpty) {
          accountMatch = model.accountId == accountId;
        }
        if (category != null && category.isNotEmpty) {
          categoryMatch = model.categoryId == category; // Filter by ID
        }
        return dateMatch && categoryMatch && accountMatch;
      }).toList();
      log.fine("[IncomeRepo] Filtered to ${filteredModels.length} models.");

      // Sort models
      filteredModels.sort((a, b) => b.date.compareTo(a.date));

      return Right(filteredModels); // Return models
    } on CacheFailure catch (e) {
      log.warning(
          "[IncomeRepo] CacheFailure getting income models: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[IncomeRepo] Unexpected error getting income models$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error getting income models: ${e.toString()}'));
    }
  }
  // --- END MODIFIED ---

  // --- Keep deleteIncome, getTotalIncomeForAccount ---
  // --- updateIncomeCategorization, reassignIncomesCategory AS IS ---
  @override
  Future<Either<Failure, void>> deleteIncome(String id) async {
    log.info("[IncomeRepo] Deleting income (ID: $id).");
    try {
      await localDataSource.deleteIncome(id);
      log.info("[IncomeRepo] Delete successful for ID: $id.");
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning(
          "[IncomeRepo] CacheFailure deleting income ID $id: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[IncomeRepo] Unexpected error deleting income ID $id$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error deleting income: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalIncomeForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate}) async {
    log.info(
        "[IncomeRepo] Getting total income for account: $accountId, Start=$startDate, End=$endDate");
    try {
      // Use the modified getIncomes which returns models
      final allModelsResult = await getIncomes(
          accountId: accountId.isEmpty ? null : accountId,
          startDate: startDate,
          endDate: endDate);

      return allModelsResult.fold(
        (failure) {
          log.warning(
              "[IncomeRepo] Failed to get models while calculating total for account '$accountId': ${failure.message}");
          return Left(failure);
        },
        (models) {
          double total = models.fold(0.0, (sum, item) => sum + item.amount);
          log.info(
              "[IncomeRepo] Calculated total income for account '$accountId': $total");
          return Right(total);
        },
      );
    } catch (e, s) {
      log.severe(
          "[IncomeRepo] Unexpected error calculating total income for account '$accountId'$e$s");
      return Left(UnexpectedFailure(
          'Failed to calculate total income: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateIncomeCategorization(
      String incomeId,
      String? categoryId,
      CategorizationStatus status,
      double? confidenceScore) async {
    log.info(
        "[IncomeRepo] updateIncomeCategorization called for ID: $incomeId, CatID: $categoryId, Status: ${status.name}");
    try {
      final existingModel = await localDataSource.getIncomeById(incomeId);
      if (existingModel == null) {
        log.warning(
            "[IncomeRepo] Income not found for categorization update: $incomeId");
        return const Left(CacheFailure("Income not found."));
      }
      final updatedModel = IncomeModel(
          id: existingModel.id,
          title: existingModel.title,
          amount: existingModel.amount,
          date: existingModel.date,
          accountId: existingModel.accountId,
          notes: existingModel.notes,
          categoryId: categoryId, // Assign new ID
          categorizationStatusValue: status.value, // Assign new status
          confidenceScoreValue: confidenceScore); // Assign new score
      await localDataSource.updateIncome(updatedModel);
      log.info(
          "[IncomeRepo] Income categorization updated successfully for ID: $incomeId");
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning(
          "[IncomeRepo] CacheFailure during updateIncomeCategorization ID $incomeId: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe(
          "[IncomeRepo] Unexpected error in updateIncomeCategorization ID $incomeId$e$s");
      return Left(CacheFailure(
          "Failed to update income categorization: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, int>> reassignIncomesCategory(
      String oldCategoryId, String newCategoryId) async {
    log.info(
        "[IncomeRepo] Reassigning incomes from CatID '$oldCategoryId' to '$newCategoryId'.");
    int updateCount = 0;
    try {
      final allModels = await localDataSource.getIncomes();
      final modelsToUpdate = allModels
          .where((model) => model.categoryId == oldCategoryId)
          .toList();

      if (modelsToUpdate.isEmpty) {
        log.info(
            "[IncomeRepo] No incomes found with category ID '$oldCategoryId'. No reassignment needed.");
        return const Right(0);
      }
      log.info(
          "[IncomeRepo] Found ${modelsToUpdate.length} incomes to reassign.");

      List<Future<void>> updateFutures = [];
      for (final model in modelsToUpdate) {
        final updatedModel = IncomeModel(
          id: model.id, title: model.title, amount: model.amount,
          date: model.date,
          accountId: model.accountId, notes: model.notes,
          categoryId: newCategoryId, // Assign new category ID
          categorizationStatusValue:
              CategorizationStatus.categorized.value, // Mark as categorized
          confidenceScoreValue: null, // Clear confidence
        );
        updateFutures.add(localDataSource.updateIncome(updatedModel));
        updateCount++;
      }
      await Future.wait(updateFutures);

      log.info(
          "[IncomeRepo] Successfully triggered updates for $updateCount incomes from '$oldCategoryId' to '$newCategoryId'.");
      return Right(updateCount);
    } on CacheFailure catch (e) {
      log.warning(
          "[IncomeRepo] CacheFailure during reassignIncomesCategory: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe(
          "[IncomeRepo] Unexpected error during reassignIncomesCategory$e$s");
      return Left(CacheFailure(
          "Failed to reassign income categories: ${e.toString()}"));
    }
  }
}
