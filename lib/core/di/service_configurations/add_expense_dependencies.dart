import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/add_expense/data/repositories/outbox_add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/domain/logic/split_preview_engine.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/core/services/image_compression_service.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';

class AddExpenseDependencies {
  static void register() {
    if (!sl.isRegistered<SplitPreviewEngine>()) {
      sl.registerLazySingleton(() => SplitPreviewEngine());
    }

    if (!sl.isRegistered<ImageCompressionService>()) {
      sl.registerLazySingleton(() => ImageCompressionService());
    }

    if (!sl.isRegistered<AddExpenseRepository>()) {
      sl.registerLazySingleton<AddExpenseRepository>(
        () => OutboxAddExpenseRepository(
          outbox: sl(),
          uuid: sl(),
          profileBox: sl(),
        ),
      );
    }

    sl.registerFactory(
      () => AddExpenseWizardBloc(
        repository: sl(),
        groupsRepository: sl(),
        currentUserId: (sl<SessionCubit>().state is SessionAuthenticated)
            ? (sl<SessionCubit>().state as SessionAuthenticated).userId
            : '',
        splitEngine: sl(),
        imageCompressionService: sl(),
        supabase: sl(),
        uuid: sl(),
        profileBox: sl(),
      ),
    );
  }
}
