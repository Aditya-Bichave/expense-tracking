import 'package:hive/hive.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/core/error/failure.dart';

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
      return account;
    } catch (e) {
      throw CacheFailure('Failed to add account to cache: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAssetAccount(String id) async {
    try {
      await accountBox.delete(id);
    } catch (e) {
      throw CacheFailure(
          'Failed to delete account from cache: ${e.toString()}');
    }
  }

  @override
  Future<List<AssetAccountModel>> getAssetAccounts() async {
    try {
      return accountBox.values.toList();
    } catch (e) {
      throw CacheFailure('Failed to get accounts from cache: ${e.toString()}');
    }
  }

  @override
  Future<AssetAccountModel> updateAssetAccount(
      AssetAccountModel account) async {
    try {
      await accountBox.put(account.id, account);
      return account;
    } catch (e) {
      throw CacheFailure('Failed to update account in cache: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await accountBox.clear();
    } catch (e) {
      throw CacheFailure('Failed to clear account cache: ${e.toString()}');
    }
  }
}
