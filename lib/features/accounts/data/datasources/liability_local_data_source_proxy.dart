import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/accounts/data/datasources/liability_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/models/liability_model.dart';
import 'package:expense_tracker/main.dart'; // logger

class DemoAwareLiabilityDataSource implements LiabilityLocalDataSource {
  final HiveLiabilityLocalDataSource hiveDataSource;
  final DemoModeService demoModeService;

  DemoAwareLiabilityDataSource({
    required this.hiveDataSource,
    required this.demoModeService,
  });

  @override
  Future<LiabilityModel> addLiability(LiabilityModel liability) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareLiabilityDS] Adding demo liability: ${liability.name}");
      // return demoModeService.addDemoLiability(liability);
      throw UnimplementedError();
    } else {
      return hiveDataSource.addLiability(liability);
    }
  }

  @override
  Future<void> deleteLiability(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareLiabilityDS] Deleting demo liability ID: $id");
      // return demoModeService.deleteDemoLiability(id);
      throw UnimplementedError();
    } else {
      return hiveDataSource.deleteLiability(id);
    }
  }

  @override
  Future<List<LiabilityModel>> getLiabilities() async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareLiabilityDS] Getting demo liabilities.");
      // return demoModeService.getDemoLiabilities();
      throw UnimplementedError();
    } else {
      return hiveDataSource.getLiabilities();
    }
  }

  @override
  Future<LiabilityModel> updateLiability(
      LiabilityModel liability) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareLiabilityDS] Updating demo liability: ${liability.name}");
      // return demoModeService.updateDemoLiability(liability);
      throw UnimplementedError();
    } else {
      return hiveDataSource.updateLiability(liability);
    }
  }

  @override
  Future<void> clearAll() async {
    if (demoModeService.isDemoActive) {
      log.warning(
          "[DemoAwareLiabilityDS] clearAll called in Demo Mode. Ignoring.");
      return;
    } else {
      return hiveDataSource.clearAll();
    }
  }
}
