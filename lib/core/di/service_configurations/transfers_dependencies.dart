import 'package:expense_tracker/features/transfers/data/datasources/transfer_local_data_source.dart';
import 'package:expense_tracker/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:expense_tracker/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:expense_tracker/features/transfers/domain/usecases/add_transfer.dart';
import 'package:expense_tracker/features/transfers/domain/usecases/delete_transfer.dart';
import 'package:expense_tracker/features/transfers/domain/usecases/get_transfers.dart';
import 'package:expense_tracker/features/transfers/domain/usecases/update_transfer.dart';

import '../service_locator.dart';

class TransfersDependencies {
  static void register() {
    // DATA SOURCES
    sl.registerLazySingleton<TransferLocalDataSource>(
      () => TransferLocalDataSourceImpl(sl()),
    );

    // REPOSITORIES
    sl.registerLazySingleton<TransferRepository>(
      () => TransferRepositoryImpl(sl()),
    );

    // USE CASES
    sl.registerLazySingleton(() => AddTransfer(sl()));
    sl.registerLazySingleton(() => GetTransfers(sl()));
    sl.registerLazySingleton(() => UpdateTransfer(sl()));
    sl.registerLazySingleton(() => DeleteTransfer(sl()));
  }
}
