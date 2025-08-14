import 'package:hive/hive.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/main.dart'; // Import logger

abstract class IncomeLocalDataSource {
  Future<List<IncomeModel>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  });
  Future<IncomeModel?> getIncomeById(String id); // ADDED: Return nullable
  Future<IncomeModel> addIncome(IncomeModel income);
  Future<IncomeModel> updateIncome(IncomeModel income);
  Future<void> deleteIncome(String id);
  Future<void> clearAll();
}

class HiveIncomeLocalDataSource implements IncomeLocalDataSource {
  final Box<IncomeModel> incomeBox;

  HiveIncomeLocalDataSource(this.incomeBox);

  @override
  Future<IncomeModel> addIncome(IncomeModel income) async {
    try {
      await incomeBox.put(income.id, income);
      log.info("Added income '${income.title}' (ID: ${income.id}) to Hive.");
      return income;
    } catch (e, s) {
      log.severe("Failed to add income '${income.title}' to cache$e$s");
      throw CacheFailure('Failed to add income: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    try {
      await incomeBox.delete(id);
      log.info("Deleted income (ID: $id) from Hive.");
    } catch (e, s) {
      log.severe("Failed to delete income (ID: $id) from cache$e$s");
      throw CacheFailure('Failed to delete income: ${e.toString()}');
    }
  }

  @override
  Future<List<IncomeModel>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) async {
    try {
      final List<IncomeModel> results = [];
      for (final income in incomeBox.values) {
        if (startDate != null) {
          final incDateOnly = DateTime(
            income.date.year,
            income.date.month,
            income.date.day,
          );
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          if (incDateOnly.isBefore(startDateOnly)) continue;
        }
        if (endDate != null) {
          final endDateInclusive = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (income.date.isAfter(endDateInclusive)) continue;
        }
        if (accountId != null && accountId.isNotEmpty) {
          final ids = accountId.split(',');
          if (!ids.contains(income.accountId)) continue;
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          final ids = categoryId.split(',');
          if (!ids.contains(income.categoryId)) continue;
        }
        results.add(income);
      }
      log.info(
        "Retrieved ${results.length} incomes from Hive after applying filters.",
      );
      return results;
    } catch (e, s) {
      log.severe("Failed to get incomes from cache$e$s");
      throw CacheFailure('Failed to get incomes: ${e.toString()}');
    }
  }

  // --- ADDED IMPLEMENTATION ---
  @override
  Future<IncomeModel?> getIncomeById(String id) async {
    try {
      final income = incomeBox.get(id);
      if (income != null) {
        log.fine("Retrieved income by ID $id from Hive.");
      } else {
        log.warning("Income with ID $id not found in Hive.");
      }
      return income; // Returns null if not found
    } catch (e, s) {
      log.severe("Failed to get income by ID $id from cache$e$s");
      throw CacheFailure('Failed to get income by ID: ${e.toString()}');
    }
  }
  // --- END ADDED ---

  @override
  Future<IncomeModel> updateIncome(IncomeModel income) async {
    // Ensure the income exists before updating
    if (!incomeBox.containsKey(income.id)) {
      log.warning("Attempted to update non-existent income ID: ${income.id}");
      throw CacheFailure("Income with ID ${income.id} not found for update.");
    }
    try {
      await incomeBox.put(income.id, income);
      log.info("Updated income '${income.title}' (ID: ${income.id}) in Hive.");
      return income;
    } catch (e, s) {
      log.severe("Failed to update income '${income.title}' in cache$e$s");
      throw CacheFailure('Failed to update income: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final count = await incomeBox.clear();
      log.info("Cleared income box in Hive ($count items removed).");
    } catch (e, s) {
      log.severe("Failed to clear income cache$e$s");
      throw CacheFailure('Failed to clear income cache: ${e.toString()}');
    }
  }
}
