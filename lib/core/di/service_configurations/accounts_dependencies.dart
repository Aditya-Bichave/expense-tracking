// lib/core/di/service_configurations/accounts_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart'; // Import service
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source_proxy.dart'; // Import Proxy
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/data/repositories/asset_account_repository_impl.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart'; // Dependency
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart'; // Dependency
import 'package:hive/hive.dart'; // Needed for HiveAssetAccountLocalDataSource
import 'package:expense_tracker/features/accounts/data/datasources/liability_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/datasources/liability_local_data_source_proxy.dart';
import 'package:expense_tracker/features/accounts/data/repositories/liability_repository_impl.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/liability_repository.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_liabilities.dart';

class AccountDependencies {
  static void register() {
    // --- MODIFIED: Register Proxy ---
    // Data Source (Register the Proxy)
    sl.registerLazySingleton<AssetAccountLocalDataSource>(
        () => DemoAwareAccountDataSource(
              hiveDataSource:
                  sl<HiveAssetAccountLocalDataSource>(), // Pass the real one
              demoModeService: sl<DemoModeService>(),
            ));
    sl.registerLazySingleton<LiabilityLocalDataSource>(
        () => DemoAwareLiabilityDataSource(
              hiveDataSource:
                  sl<HiveLiabilityLocalDataSource>(), // Pass the real one
              demoModeService: sl<DemoModeService>(),
            ));
    // --- END MODIFIED ---

    // Repository (Depends on Income/Expense Repos)
    sl.registerLazySingleton<AssetAccountRepository>(() =>
        AssetAccountRepositoryImpl(
            localDataSource: sl(),
            incomeRepository: sl<IncomeRepository>(),
            expenseRepository: sl<ExpenseRepository>()));
    sl.registerLazySingleton<LiabilityRepository>(() =>
        LiabilityRepositoryImpl(
            localDataSource: sl(),
            transactionRepository: sl<TransactionRepository>()));
    // Use Cases
    sl.registerLazySingleton(() => AddAssetAccountUseCase(sl()));
    sl.registerLazySingleton(() => GetAssetAccountsUseCase(sl()));
    sl.registerLazySingleton(() => UpdateAssetAccountUseCase(sl()));
    sl.registerLazySingleton(() => DeleteAssetAccountUseCase(sl()));
    sl.registerLazySingleton(() => GetLiabilitiesUseCase(sl()));
    // Blocs
    sl.registerFactoryParam<AddEditAccountBloc, AssetAccount?, void>(
        (initialAccount, _) => AddEditAccountBloc(
            addAssetAccountUseCase: sl(),
            updateAssetAccountUseCase: sl(),
            initialAccount: initialAccount));
    sl.registerFactory(() => AccountListBloc(
        getAssetAccountsUseCase: sl(),
        getLiabilitiesUseCase: sl(),
        deleteAssetAccountUseCase: sl(),
        dataChangeStream: sl<Stream<DataChangedEvent>>()));
  }
}
