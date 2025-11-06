import 'package:hive/hive.dart';
import 'package:expense_tracker/features/accounts/data/models/liability_model.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/main.dart'; // Import logger

abstract class LiabilityLocalDataSource {
  Future<List<LiabilityModel>> getLiabilities();
  Future<LiabilityModel> addLiability(LiabilityModel liability);
  Future<LiabilityModel> updateLiability(LiabilityModel liability);
  Future<void> deleteLiability(String id);
  Future<void> clearAll(); // Optional
}

class HiveLiabilityLocalDataSource implements LiabilityLocalDataSource {
  final Box<LiabilityModel> liabilityBox;

  HiveLiabilityLocalDataSource(this.liabilityBox);

  @override
  Future<LiabilityModel> addLiability(LiabilityModel liability) async {
    try {
      await liabilityBox.put(liability.id, liability);
      log.info(
          "Added liability '${liability.name}' (ID: ${liability.id}) to Hive.");
      return liability;
    } catch (e, s) {
      log.severe("Failed to add liability '${liability.name}' to cache$e$s");
      throw CacheFailure('Failed to add liability: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteLiability(String id) async {
    try {
      await liabilityBox.delete(id);
      log.info("Deleted liability (ID: $id) from Hive.");
    } catch (e, s) {
      log.severe("Failed to delete liability (ID: $id) from cache$e$s");
      throw CacheFailure('Failed to delete liability: ${e.toString()}');
    }
  }

  @override
  Future<List<LiabilityModel>> getLiabilities() async {
    try {
      final liabilities = liabilityBox.values.toList();
      log.info("Retrieved ${liabilities.length} liabilities from Hive.");
      return liabilities;
    } catch (e, s) {
      log.severe("Failed to get liabilities from cache$e$s");
      throw CacheFailure('Failed to get liabilities: ${e.toString()}');
    }
  }

  @override
  Future<LiabilityModel> updateLiability(
      LiabilityModel liability) async {
    try {
      await liabilityBox.put(liability.id, liability);
      log.info(
          "Updated liability '${liability.name}' (ID: ${liability.id}) in Hive.");
      return liability;
    } catch (e, s) {
      log.severe(
          "Failed to update liability '${liability.name}' in cache$e$s");
      throw CacheFailure('Failed to update liability: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final count = await liabilityBox.clear();
      log.info("Cleared liabilities box in Hive ($count items removed).");
    } catch (e, s) {
      log.severe("Failed to clear liabilities cache$e$s");
      throw CacheFailure('Failed to clear liabilities cache: ${e.toString()}');
    }
  }
}
