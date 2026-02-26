import 'dart:async';

import 'package:expense_tracker/core/di/service_configurations/goal_dependencies.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/services/clock.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/archive_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/audit_goal_totals.dart';
import 'package:expense_tracker/features/goals/domain/usecases/check_goal_achievement.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

// Mocks
class MockGoalLocalDataSource extends Mock implements GoalLocalDataSource {}
class MockGoalContributionLocalDataSource extends Mock implements GoalContributionLocalDataSource {}
class MockDemoModeService extends Mock implements DemoModeService {}
class MockGoalRepository extends Mock implements GoalRepository {}
class MockGoalContributionRepository extends Mock implements GoalContributionRepository {}
class MockAddGoalUseCase extends Mock implements AddGoalUseCase {}
class MockGetGoalsUseCase extends Mock implements GetGoalsUseCase {}
class MockUpdateGoalUseCase extends Mock implements UpdateGoalUseCase {}
class MockArchiveGoalUseCase extends Mock implements ArchiveGoalUseCase {}
class MockDeleteGoalUseCase extends Mock implements DeleteGoalUseCase {}
class MockAddContributionUseCase extends Mock implements AddContributionUseCase {}
class MockGetContributionsForGoalUseCase extends Mock implements GetContributionsForGoalUseCase {}
class MockUpdateContributionUseCase extends Mock implements UpdateContributionUseCase {}
class MockDeleteContributionUseCase extends Mock implements DeleteContributionUseCase {}
class MockCheckGoalAchievementUseCase extends Mock implements CheckGoalAchievementUseCase {}
class MockAuditGoalTotalsUseCase extends Mock implements AuditGoalTotalsUseCase {}
class MockUuid extends Mock implements Uuid {}
class MockClock extends Mock implements Clock {}

final sl = GetIt.instance;

void main() {
  setUp(() async {
    await sl.reset();
  });

  test('GoalDependencies registers dependencies and Blocs resolve correctly', () {
    // 1. Register Mock Dependencies that GoalDependencies expects to find or creates
    // Note: GoalDependencies registers UseCases if not present.
    // Ideally we want to verify that GoalDependencies wires up the Blocs using the UseCases it registered OR ones we provide.

    // To ensure we test the wiring in GoalDependencies, we should let it register things, OR register mocks for leaf dependencies.

    // Leaf dependencies needed by Repositories/DataSources:
    // Hive DataSources are used in DemoAware Proxies.
    // GoalDependencies registers:
    // - GoalLocalDataSource (DemoAware) -> needs HiveGoalLocalDataSource (we can mock this or just mock GoalLocalDataSource and register it FIRST to skip internal logic)

    // Strategy: Register Mocks for UseCases. GoalDependencies checks `!sl.isRegistered`.
    // If we register Mocks, GoalDependencies won't register real ones.
    // BUT we want to test the Bloc wiring which happens at the end.
    // The Bloc wiring uses `sl<UseCase>()`.

    sl.registerLazySingleton<AddGoalUseCase>(() => MockAddGoalUseCase());
    sl.registerLazySingleton<UpdateGoalUseCase>(() => MockUpdateGoalUseCase());
    sl.registerLazySingleton<AddContributionUseCase>(() => MockAddContributionUseCase());
    sl.registerLazySingleton<UpdateContributionUseCase>(() => MockUpdateContributionUseCase());
    sl.registerLazySingleton<DeleteContributionUseCase>(() => MockDeleteContributionUseCase());
    sl.registerLazySingleton<CheckGoalAchievementUseCase>(() => MockCheckGoalAchievementUseCase());

    // Required for other Blocs/UseCases if we triggered them
    sl.registerLazySingleton<GetGoalsUseCase>(() => MockGetGoalsUseCase());
    sl.registerLazySingleton<ArchiveGoalUseCase>(() => MockArchiveGoalUseCase());
    sl.registerLazySingleton<DeleteGoalUseCase>(() => MockDeleteGoalUseCase());

    // Required for Uuid injection
    sl.registerLazySingleton<Uuid>(() => MockUuid());

    // 2. Call register
    GoalDependencies.register();

    // 3. Verify Blocs are registered
    expect(sl.isRegistered<AddEditGoalBloc>(), true);
    expect(sl.isRegistered<LogContributionBloc>(), true);

    // 4. Resolve Blocs to trigger the factory closures (and cover the lines using `sl<Uuid>()`)
    final addEditBloc = sl<AddEditGoalBloc>(param1: null);
    expect(addEditBloc, isA<AddEditGoalBloc>());

    final logContributionBloc = sl<LogContributionBloc>();
    expect(logContributionBloc, isA<LogContributionBloc>());
  });
}
