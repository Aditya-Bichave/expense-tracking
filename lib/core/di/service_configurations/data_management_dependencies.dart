// lib/core/di/service_configurations/data_management_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/data/repositories/data_management_repository_impl.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';

class DataManagementDependencies {
  static void register() {
    // Repository
    sl.registerLazySingleton<DataManagementRepository>(
      () => DataManagementRepositoryImpl(
        accountBox: sl(), // These boxes are registered in main locator
        expenseBox: sl(),
        incomeBox: sl(),
        categoryBox: sl(),
        userHistoryBox: sl(),
        budgetBox: sl(),
        goalBox: sl(),
        contributionBox: sl(),
        recurringRuleBox: sl(),
        recurringRuleAuditLogBox: sl(),
        outboxBox: sl(),
        groupBox: sl(),
        groupMemberBox: sl(),
        groupExpenseBox: sl(),
      ),
    );
    // Use Cases
    sl.registerLazySingleton(
      () => BackupDataUseCase(
        dataManagementRepository: sl(),
        downloaderService: sl(),
      ),
    );
    sl.registerLazySingleton(() => RestoreDataUseCase(sl()));
    sl.registerLazySingleton(() => ClearAllDataUseCase(sl()));
    // BLoC
    sl.registerFactory(
      () => DataManagementBloc(
        backupDataUseCase: sl(),
        restoreDataUseCase: sl(),
        clearAllDataUseCase: sl(),
      ),
    );
  }
}
