import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/logger.dart';

abstract class AssetAccountLocalDataSource {
  Future<List<AssetAccountModel>> getAssetAccounts();
  Future<AssetAccountModel> addAssetAccount(AssetAccountModel account);
  Future<AssetAccountModel> updateAssetAccount(AssetAccountModel account);
  Future<void> deleteAssetAccount(String id);
  Future<void> clearAll(); // Optional
}

class HiveAssetAccountLocalDataSource implements AssetAccountLocalDataSource {
  final Box<AssetAccountModel> accountBox;

  HiveAssetAccountLocalDataSource(this.accountBox);

  @override
  Future<AssetAccountModel> addAssetAccount(AssetAccountModel account) async {
    try {
      await accountBox.put(account.id, account);
      log.info(
        "Added asset account '${account.name}' (ID: ${account.id}) to Hive.",
      );
      return account;
    } catch (e, s) {
      log.severe("Failed to add asset account '${account.name}' to cache$e$s");
      throw CacheFailure('Failed to add account: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAssetAccount(String id) async {
    try {
      await accountBox.delete(id);
      log.info("Deleted asset account (ID: $id) from Hive.");
    } catch (e, s) {
      log.severe("Failed to delete asset account (ID: $id) from cache$e$s");
      throw CacheFailure('Failed to delete account: ${e.toString()}');
    }
  }

  @override
  Future<List<AssetAccountModel>> getAssetAccounts() async {
    try {
      final accounts = accountBox.values.toList();
      log.info("Retrieved ${accounts.length} asset accounts from Hive.");
      return accounts;
    } catch (e, s) {
      log.severe("Failed to get asset accounts from cache$e$s");
      throw CacheFailure('Failed to get accounts: ${e.toString()}');
    }
  }

  @override
  Future<AssetAccountModel> updateAssetAccount(
    AssetAccountModel account,
  ) async {
    try {
      await accountBox.put(account.id, account);
      log.info(
        "Updated asset account '${account.name}' (ID: ${account.id}) in Hive.",
      );
      return account;
    } catch (e, s) {
      log.severe(
        "Failed to update asset account '${account.name}' in cache$e$s",
      );
      throw CacheFailure('Failed to update account: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final count = await accountBox.clear();
      log.info("Cleared asset accounts box in Hive ($count items removed).");
    } catch (e, s) {
      log.severe("Failed to clear asset accounts cache$e$s");
      throw CacheFailure('Failed to clear accounts cache: ${e.toString()}');
    }
  }
}
