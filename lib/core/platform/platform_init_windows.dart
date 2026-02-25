import 'dart:io';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:expense_tracker/core/utils/logger.dart';

Future<void> initPlatform(List<String> args) async {
  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      "io.supabase.expensetracker",
      onSecondWindow: (args) {
        log.info("Second instance detected with args: $args");
        if (sl.isRegistered<DeepLinkBloc>()) {
          sl<DeepLinkBloc>().add(DeepLinkStarted(args: args));
        }
      },
    );
  }
}
