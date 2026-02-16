import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/main.dart'; // logger

/// A proxy DataSource that either interacts with the real Hive source
/// or the in-memory demo data source based on the DemoModeService.
class DemoAwareGoalDataSource implements GoalLocalDataSource {
  final HiveGoalLocalDataSource hiveDataSource;
  final DemoModeService demoModeService;

  DemoAwareGoalDataSource({
    required this.hiveDataSource,
    required this.demoModeService,
  });

  @override
  Future<List<GoalModel>> getGoals() async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareGoalDS] Getting demo goals.");
      return demoModeService.getDemoGoals();
    } else {
      return hiveDataSource.getGoals();
    }
  }

  @override
  Future<GoalModel?> getGoalById(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareGoalDS] Getting demo goal by ID: $id");
      return demoModeService.getDemoGoalById(id);
    } else {
      return hiveDataSource.getGoalById(id);
    }
  }

  @override
  Future<void> saveGoal(GoalModel goal) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareGoalDS] Saving demo goal: ${goal.name}");
      return demoModeService.saveDemoGoal(goal);
    } else {
      return hiveDataSource.saveGoal(goal);
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareGoalDS] Deleting demo goal ID: $id");
      // Also delete demo contributions for this goal? Or handle in Service.
      // Let's assume Service handles it for now if needed.
      return demoModeService.deleteDemoGoal(id);
    } else {
      return hiveDataSource.deleteGoal(id);
    }
  }

  @override
  Future<void> clearAllGoals() async {
    if (demoModeService.isDemoActive) {
      log.warning(
        "[DemoAwareGoalDS] clearAllGoals called in Demo Mode. Ignoring.",
      );
      return;
    } else {
      return hiveDataSource.clearAllGoals();
    }
  }
}
