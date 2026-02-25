import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:expense_tracker/core/utils/logger.dart';

/// A proxy DataSource that either interacts with the real Hive source
/// or the in-memory demo data source based on the DemoModeService.
class DemoAwareAccountDataSource implements AssetAccountLocalDataSource {
  final HiveAssetAccountLocalDataSource hiveDataSource;
  final DemoModeService demoModeService;

  DemoAwareAccountDataSource({
    required this.hiveDataSource,
    required this.demoModeService,
  });

  @override
  Future<AssetAccountModel> addAssetAccount(AssetAccountModel account) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareAccountDS] Adding demo account: ${account.name}");
      return demoModeService.addDemoAccount(account);
    } else {
      return hiveDataSource.addAssetAccount(account);
    }
  }

  @override
  Future<void> deleteAssetAccount(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareAccountDS] Deleting demo account ID: $id");
      return demoModeService.deleteDemoAccount(id);
    } else {
      // Note: The real delete has transaction checks in the repository layer
      return hiveDataSource.deleteAssetAccount(id);
    }
  }

  @override
  Future<List<AssetAccountModel>> getAssetAccounts() async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareAccountDS] Getting demo accounts.");
      return demoModeService.getDemoAccounts();
    } else {
      return hiveDataSource.getAssetAccounts();
    }
  }

  @override
  Future<AssetAccountModel> updateAssetAccount(
    AssetAccountModel account,
  ) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareAccountDS] Updating demo account: ${account.name}");
      return demoModeService.updateDemoAccount(account);
    } else {
      return hiveDataSource.updateAssetAccount(account);
    }
  }

  @override
  Future<void> clearAll() async {
    if (demoModeService.isDemoActive) {
      log.warning(
        "[DemoAwareAccountDS] clearAll called in Demo Mode. Ignoring.",
      );
      return;
    } else {
      return hiveDataSource.clearAll();
    }
  }
}
