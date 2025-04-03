// lib/features/income/data/repositories/income_repository_impl.dart
// REFINED FILE

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
  // Use getter for lazy initialization via Service Locator
  CategoryRepository get categoryRepository => sl<CategoryRepository>();

  IncomeRepositoryImpl({required this.localDataSource});

  // Helper function to hydrate categories for a list of income models
  Future<Either<Failure, List<Income>>> _hydrateCategories(
      List<IncomeModel> incomeModels) async {
    if (incomeModels.isEmpty) return const Right([]);
    log.fine(
        "[IncomeRepo._hydrateCategories] Hydrating ${incomeModels.length} models.");

    // Fetch all categories (leveraging repository cache if possible)
    final categoryResult = await categoryRepository.getAllCategories();
    return categoryResult.fold(
      (failure) {
        log.warning(
            "[IncomeRepo._hydrateCategories] Failed to get categories for hydration: ${failure.message}");
        return Left(failure); // Propagate the category fetch failure
      },
      (allCategories) {
        // Create a lookup map for efficient access
        final categoryMap = {for (var cat in allCategories) cat.id: cat};
        final hydratedIncomes = <Income>[];

        for (final model in incomeModels) {
          final category = categoryMap[model.categoryId];
          if (model.categoryId != null && category == null) {
            log.warning(
                "[IncomeRepo._hydrateCategories] Category ID '${model.categoryId}' found on income '${model.id}' but not in fetched category list! Treating as Uncategorized.");
          }
          // Convert model to entity and immediately add the looked-up category
          hydratedIncomes.add(Income(
            id: model.id,
            title: model.title,
            amount: model.amount,
            date: model.date,
            accountId: model.accountId,
            notes: model.notes,
            status: CategorizationStatusExtension.fromValue(
                model.categorizationStatusValue),
            confidenceScore: model.confidenceScoreValue,
            // Assign looked-up category (or null if not found/not set)
            category: category,
          ));
        }
        log.fine(
            "[IncomeRepo._hydrateCategories] Hydration complete for ${hydratedIncomes.length} incomes.");
        return Right(hydratedIncomes);
      },
    );
  }

  @override
  Future<Either<Failure, Income>> addIncome(Income income) async {
    log.info("[IncomeRepo] Adding income '${income.title}'.");
    try {
      final incomeModel = IncomeModel.fromEntity(income);
      final addedModel = await localDataSource.addIncome(incomeModel);
      log.info(
          "[IncomeRepo] Add successful (ID: ${addedModel.id}). Hydrating category for return.");
      // Hydrate the single added income
      final hydratedResult = await _hydrateCategories([addedModel]);
      return hydratedResult.fold(
        (failure) {
          log.warning(
              "[IncomeRepo] Failed hydration after adding income '${addedModel.id}': ${failure.message}");
          // Return the failure, but the income *was* added to the DB
          return Left(failure);
        },
        (hydratedList) => Right(hydratedList.first),
      );
    } on CacheFailure catch (e) {
      log.severe("[IncomeRepo] CacheFailure adding income: ${e.message}");
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
  Future<Either<Failure, List<Income>>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Assumed to be category ID
    String? accountId,
  }) async {
    log.info(
        "[IncomeRepo] Getting incomes. Filters: AccID=$accountId, Start=$startDate, End=$endDate, CatID=$category");
    try {
      final incomeModels = await localDataSource.getIncomes();
      log.info("[IncomeRepo] Fetched ${incomeModels.length} income models.");

      // Apply filtering on MODELS (before hydration)
      final originalCount = incomeModels.length;
      final filteredModels = incomeModels.where((model) {
        bool dateMatch = true;
        bool categoryMatch = true;
        bool accountMatch = true;

        // Date filtering
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
        // Account filtering
        if (accountId != null && accountId.isNotEmpty) {
          accountMatch = model.accountId == accountId;
        }
        // Category filtering (Assumes 'category' filter param holds the ID)
        if (category != null && category.isNotEmpty) {
          categoryMatch = model.categoryId == category;
        }
        return dateMatch && categoryMatch && accountMatch;
      }).toList();
      log.info(
          "[IncomeRepo] Filtered models: ${filteredModels.length} remaining from $originalCount.");

      // Sort MODELS by date descending
      filteredModels.sort((a, b) => b.date.compareTo(a.date));
      log.fine("[IncomeRepo] Sorted ${filteredModels.length} models.");

      // Hydrate categories for the filtered list
      return await _hydrateCategories(filteredModels);
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
      log.info(
          "[IncomeRepo] Update successful (ID: ${updatedModel.id}). Hydrating category for return.");
      // Hydrate the single updated income
      final hydratedResult = await _hydrateCategories([updatedModel]);
      return hydratedResult.fold(
        (failure) {
          log.warning(
              "[IncomeRepo] Failed hydration after updating income '${updatedModel.id}': ${failure.message}");
          // Return the failure, but the income *was* updated in the DB
          return Left(failure);
        },
        (hydratedList) => Right(hydratedList.first),
      );
    } on CacheFailure catch (e) {
      log.warning("[IncomeRepo] CacheFailure updating income: ${e.message}");
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
      final allIncomesResult = await getIncomes(
          accountId: accountId.isEmpty ? null : accountId,
          startDate: startDate,
          endDate: endDate);

      return allIncomesResult.fold(
        (failure) {
          log.warning(
              "[IncomeRepo] Failed to get incomes while calculating total for account '$accountId': ${failure.message}");
          return Left(failure); // Propagate the failure
        },
        (incomes) {
          double total = incomes.fold(0.0, (sum, item) => sum + item.amount);
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
      // Fetch the existing model to preserve other fields
      final existingModel = await localDataSource.getIncomeById(incomeId);
      if (existingModel == null) {
        log.warning(
            "[IncomeRepo] Income not found for categorization update: $incomeId");
        return const Left(CacheFailure("Income not found."));
      }

      // Create the updated model with new categorization details
      final updatedModel = IncomeModel(
        id: existingModel.id,
        title: existingModel.title,
        amount: existingModel.amount,
        date: existingModel.date,
        accountId: existingModel.accountId,
        notes: existingModel.notes,
        // --- Updated fields ---
        categoryId: categoryId, // Can be null
        categorizationStatusValue: status.value,
        confidenceScoreValue: confidenceScore,
        // --- End Updated fields ---
      );

      // Save the updated model
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
}
