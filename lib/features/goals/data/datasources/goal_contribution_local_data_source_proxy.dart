import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:expense_tracker/core/utils/logger.dart';

/// A proxy DataSource that either interacts with the real Hive source
/// or the in-memory demo data source based on the DemoModeService.
class DemoAwareGoalContributionDataSource
    implements GoalContributionLocalDataSource {
  final HiveContributionLocalDataSource hiveDataSource;
  final DemoModeService demoModeService;

  DemoAwareGoalContributionDataSource({
    required this.hiveDataSource,
    required this.demoModeService,
  });

  @override
  Future<List<GoalContributionModel>> getAllContributions() async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareContribDS] Getting all demo contributions.");
      return demoModeService.getAllDemoContributions();
    } else {
      return hiveDataSource.getAllContributions();
    }
  }

  @override
  Future<List<GoalContributionModel>> getContributionsForGoal(
    String goalId,
  ) async {
    if (demoModeService.isDemoActive) {
      log.fine(
        "[DemoAwareContribDS] Getting demo contributions for Goal ID: $goalId",
      );
      return demoModeService.getDemoContributionsForGoal(goalId);
    } else {
      return hiveDataSource.getContributionsForGoal(goalId);
    }
  }

  @override
  Future<GoalContributionModel?> getContributionById(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareContribDS] Getting demo contribution by ID: $id");
      return demoModeService.getDemoContributionById(id);
    } else {
      return hiveDataSource.getContributionById(id);
    }
  }

  @override
  Future<void> saveContribution(GoalContributionModel contribution) async {
    if (demoModeService.isDemoActive) {
      log.fine(
        "[DemoAwareContribDS] Saving demo contribution: ${contribution.id}",
      );
      return demoModeService.saveDemoContribution(contribution);
    } else {
      return hiveDataSource.saveContribution(contribution);
    }
  }

  @override
  Future<void> deleteContribution(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareContribDS] Deleting demo contribution ID: $id");
      return demoModeService.deleteDemoContribution(id);
    } else {
      return hiveDataSource.deleteContribution(id);
    }
  }

  @override
  Future<void> deleteContributions(List<String> ids) async {
    if (demoModeService.isDemoActive) {
      log.fine(
        "[DemoAwareContribDS] Deleting ${ids.length} demo contributions.",
      );
      return demoModeService.deleteDemoContributions(ids);
    } else {
      return hiveDataSource.deleteContributions(ids);
    }
  }

  @override
  Future<void> clearAllContributions() async {
    if (demoModeService.isDemoActive) {
      log.warning(
        "[DemoAwareContribDS] clearAllContributions called in Demo Mode. Ignoring.",
      );
      return;
    } else {
      return hiveDataSource.clearAllContributions();
    }
  }
}
