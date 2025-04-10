// lib/core/di/service_configurations/goal_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
// Data Sources
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source_impl.dart';
// Repositories
import 'package:expense_tracker/features/goals/data/repositories/goal_contribution_repository_impl.dart';
import 'package:expense_tracker/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
// Entities (for Bloc parameters)
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
// Use Cases
import 'package:expense_tracker/features/goals/domain/usecases/add_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/archive_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/check_goal_achievement.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_goal.dart'; // Import DeleteGoalUseCase
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_goal.dart';
// Blocs
import 'package:expense_tracker/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
// External
import 'package:uuid/uuid.dart';
import 'dart:async'; // For Stream

class GoalDependencies {
  static void register() {
    // --- Data Sources ---
    if (!sl.isRegistered<GoalLocalDataSource>()) {
      sl.registerLazySingleton<GoalLocalDataSource>(
          () => HiveGoalLocalDataSource(sl()));
    }
    if (!sl.isRegistered<GoalContributionLocalDataSource>()) {
      sl.registerLazySingleton<GoalContributionLocalDataSource>(
          () => HiveContributionLocalDataSource(sl()));
    }

    // --- Repositories ---
    if (!sl.isRegistered<GoalRepository>()) {
      sl.registerLazySingleton<GoalRepository>(
          () => GoalRepositoryImpl(localDataSource: sl()));
    }
    if (!sl.isRegistered<GoalContributionRepository>()) {
      sl.registerLazySingleton<GoalContributionRepository>(
          () => GoalContributionRepositoryImpl(
                contributionDataSource: sl(),
                goalDataSource: sl(), // Goal DS needed for cache update
              ));
    }

    // --- Use Cases ---
    if (!sl.isRegistered<AddGoalUseCase>()) {
      sl.registerLazySingleton(() => AddGoalUseCase(sl(), sl<Uuid>()));
    }
    if (!sl.isRegistered<GetGoalsUseCase>()) {
      sl.registerLazySingleton(() => GetGoalsUseCase(sl()));
    }
    if (!sl.isRegistered<UpdateGoalUseCase>()) {
      sl.registerLazySingleton(() => UpdateGoalUseCase(sl()));
    }
    if (!sl.isRegistered<ArchiveGoalUseCase>()) {
      sl.registerLazySingleton(() => ArchiveGoalUseCase(sl()));
    }
    // Register DeleteGoalUseCase
    if (!sl.isRegistered<DeleteGoalUseCase>()) {
      sl.registerLazySingleton(() => DeleteGoalUseCase(sl()));
    }
    if (!sl.isRegistered<AddContributionUseCase>()) {
      sl.registerLazySingleton(() => AddContributionUseCase(sl(), sl<Uuid>()));
    }
    if (!sl.isRegistered<GetContributionsForGoalUseCase>()) {
      sl.registerLazySingleton(() => GetContributionsForGoalUseCase(sl()));
    }
    if (!sl.isRegistered<UpdateContributionUseCase>()) {
      sl.registerLazySingleton(() => UpdateContributionUseCase(sl()));
    }
    if (!sl.isRegistered<DeleteContributionUseCase>()) {
      sl.registerLazySingleton(() => DeleteContributionUseCase(sl()));
    }
    if (!sl.isRegistered<CheckGoalAchievementUseCase>()) {
      sl.registerLazySingleton(() => CheckGoalAchievementUseCase(sl()));
    }

    // --- Blocs ---
    // Register GoalListBloc
    if (!sl.isRegistered<GoalListBloc>()) {
      sl.registerFactory(() => GoalListBloc(
            getGoalsUseCase: sl<GetGoalsUseCase>(),
            archiveGoalUseCase: sl<ArchiveGoalUseCase>(),
            dataChangeStream: sl<Stream<DataChangedEvent>>(),
            // Provide DeleteGoalUseCase explicitly
            deleteGoalUseCase: sl<DeleteGoalUseCase>(),
          ));
    }
    // Register AddEditGoalBloc (Factory with parameter)
    if (!sl.isRegistered<AddEditGoalBloc>()) {
      sl.registerFactoryParam<AddEditGoalBloc, Goal?, void>(
          (initialGoal, _) => AddEditGoalBloc(
                addGoalUseCase: sl<AddGoalUseCase>(),
                updateGoalUseCase: sl<UpdateGoalUseCase>(),
                initialGoal: initialGoal,
              ));
    }
    // Register LogContributionBloc
    if (!sl.isRegistered<LogContributionBloc>()) {
      sl.registerFactory(() => LogContributionBloc(
            addContributionUseCase: sl<AddContributionUseCase>(),
            updateContributionUseCase: sl<UpdateContributionUseCase>(),
            deleteContributionUseCase: sl<DeleteContributionUseCase>(),
            checkGoalAchievementUseCase: sl<CheckGoalAchievementUseCase>(),
          ));
    }
  }
}
