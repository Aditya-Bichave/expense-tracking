import 'package:hive/hive.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/main.dart'; // Import logger

abstract class IncomeLocalDataSource {
  Future<List<IncomeModel>> getIncomes();
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
  Future<List<IncomeModel>> getIncomes() async {
    try {
      final incomes = incomeBox.values.toList();
      log.info("Retrieved ${incomes.length} incomes from Hive.");
      return incomes;
    } catch (e, s) {
      log.severe("Failed to get incomes from cache$e$s");
      throw CacheFailure('Failed to get incomes: ${e.toString()}');
    }
  }

  @override
  Future<IncomeModel> updateIncome(IncomeModel income) async {
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
