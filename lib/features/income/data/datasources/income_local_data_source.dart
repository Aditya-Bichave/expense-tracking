import 'package:hive/hive.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/core/error/failure.dart';

abstract class IncomeLocalDataSource {
  Future<List<IncomeModel>> getIncomes();
  Future<IncomeModel> addIncome(IncomeModel income);
  Future<IncomeModel> updateIncome(IncomeModel income);
  Future<void> deleteIncome(String id);
  Future<void> clearAll(); // Optional
}

class HiveIncomeLocalDataSource implements IncomeLocalDataSource {
  final Box<IncomeModel> incomeBox;

  HiveIncomeLocalDataSource(this.incomeBox);

  @override
  Future<IncomeModel> addIncome(IncomeModel income) async {
    try {
      await incomeBox.put(income.id, income);
      return income;
    } catch (e) {
      throw CacheFailure('Failed to add income to cache: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    try {
      await incomeBox.delete(id);
    } catch (e) {
      throw CacheFailure('Failed to delete income from cache: ${e.toString()}');
    }
  }

  @override
  Future<List<IncomeModel>> getIncomes() async {
    try {
      return incomeBox.values.toList();
    } catch (e) {
      throw CacheFailure('Failed to get incomes from cache: ${e.toString()}');
    }
  }

  @override
  Future<IncomeModel> updateIncome(IncomeModel income) async {
    try {
      await incomeBox.put(income.id, income);
      return income;
    } catch (e) {
      throw CacheFailure('Failed to update income in cache: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await incomeBox.clear();
    } catch (e) {
      throw CacheFailure('Failed to clear income cache: ${e.toString()}');
    }
  }
}
