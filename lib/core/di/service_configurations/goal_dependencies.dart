// lib/core/di/service_configurations/goal_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_contribution_repository_impl.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';

import 'package:expense_tracker/features/goals/domain/usecases/update_goal.dart'; // ADDED
import 'package:expense_tracker/features/goals/domain/usecases/archive_goal.dart'; // ADDED
import 'package:expense_tracker/features/goals/domain/usecases/update_contribution.dart'; // ADDED
import 'package:expense_tracker/features/goals/domain/usecases/delete_contribution.dart'; // ADDED
import 'package:expense_tracker/features/goals/domain/usecases/check_goal_achievement.dart'; // ADDED
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
// Import Update/Delete Use Cases later
import 'package:expense_tracker/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:uuid/uuid.dart';

class GoalDependencies {
  static void register() {
    // --- Data Sources ---
    sl.registerLazySingleton<GoalLocalDataSource>(
        () => HiveGoalLocalDataSource(sl()));
    sl.registerLazySingleton<GoalContributionLocalDataSource>(
        () => HiveContributionLocalDataSource(sl()));

    // --- Repositories ---
    sl.registerLazySingleton<GoalRepository>(
        () => GoalRepositoryImpl(localDataSource: sl()));
    // Contribution repo needs Goal DS to update cache
    sl.registerLazySingleton<GoalContributionRepository>(
        () => GoalContributionRepositoryImpl(
              contributionDataSource: sl(),
              goalDataSource: sl(),
            ));

    // --- Use Cases (Phase 2) ---
    sl.registerLazySingleton(() => AddGoalUseCase(sl(), sl<Uuid>()));
    sl.registerLazySingleton(() => GetGoalsUseCase(sl()));
    sl.registerLazySingleton(() => AddContributionUseCase(sl(), sl<Uuid>()));
    sl.registerLazySingleton(() => GetContributionsForGoalUseCase(sl()));

    sl.registerLazySingleton(() => AddGoalUseCase(sl(), sl<Uuid>()));
    sl.registerLazySingleton(() => GetGoalsUseCase(sl()));
    sl.registerLazySingleton(() => UpdateGoalUseCase(sl())); // ADDED
    sl.registerLazySingleton(() => ArchiveGoalUseCase(sl())); // ADDED
    // sl.registerLazySingleton(() => DeleteGoalUseCase(sl())); // Optional
    sl.registerLazySingleton(() => AddContributionUseCase(sl(), sl<Uuid>()));
    sl.registerLazySingleton(() => GetContributionsForGoalUseCase(sl()));
    sl.registerLazySingleton(() => UpdateContributionUseCase(sl())); // ADDED
    sl.registerLazySingleton(() => DeleteContributionUseCase(sl())); // ADDED
    sl.registerLazySingleton(() => CheckGoalAchievementUseCase(sl())); // ADDED
    // Register Update/Delete/Archive Use Cases in Phase 3

    // --- Blocs ---
    sl.registerFactory(() => GoalListBloc(
          getGoalsUseCase: sl(),
          dataChangeStream: sl<Stream<DataChangedEvent>>(),
          archiveGoalUseCase: sl(),
          deleteGoalUseCase: sl(),
        ));
    sl.registerFactoryParam<AddEditGoalBloc, Goal?, void>(
        (initialGoal, _) => AddEditGoalBloc(
              addGoalUseCase: sl(),
              // updateGoalUseCase: sl(), // Add later
              initialGoal: initialGoal, updateGoalUseCase: sl(),
            ));
    sl.registerFactory(() => LogContributionBloc(
          // Not FactoryParam needed for Phase 2 Add
          addContributionUseCase: sl(),
          updateContributionUseCase: sl(),
          deleteContributionUseCase: sl(),
          checkGoalAchievementUseCase: sl(), // Add later
        ));
    sl.registerFactory(() => GoalListBloc(
          getGoalsUseCase: sl(),
          archiveGoalUseCase: sl(), // Pass Archive UseCase
          deleteGoalUseCase: sl(), // Optional
          dataChangeStream: sl<Stream<DataChangedEvent>>(),
        ));
    sl.registerFactoryParam<AddEditGoalBloc, Goal?, void>(
        (initialGoal, _) => AddEditGoalBloc(
              addGoalUseCase: sl(),
              updateGoalUseCase: sl(), // Pass Update UseCase
              initialGoal: initialGoal,
            ));
    sl.registerFactory(() => LogContributionBloc(
          addContributionUseCase: sl(),
          updateContributionUseCase: sl(), // Pass Update UseCase
          deleteContributionUseCase: sl(),
          checkGoalAchievementUseCase: sl(), // Pass Delete UseCase
        ));
  }
}
