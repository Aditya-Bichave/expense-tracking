import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/storage/app_hive_boxes.dart';
import 'package:expense_tracker/core/storage/hive_adapters.dart';
import 'package:expense_tracker/core/utils/bloc_observer.dart';
import 'package:expense_tracker/core/utils/e2e_bootstrap.dart';
import 'package:expense_tracker/core/utils/e2e_mode.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Brings up everything the widget tree assumes already exists.
///
/// The steps are ordered and each one depends on the ones before it, so they
/// read top-to-bottom in [init] rather than being hidden behind indirection.
class AppInitializer {
  const AppInitializer._();

  /// Runs the full startup sequence. Throws if any required step fails; the
  /// caller is expected to show [InitializationErrorApp] in that case.
  static Future<void> init() async {
    Bloc.observer = SimpleBlocObserver();

    await _initFirebase();
    await Hive.initFlutter();

    // Supabase must be up before the service locator, which resolves clients
    // from it while registering dependencies.
    await SupabaseClientProvider.initialize();

    final secureStorageService = SecureStorageService();
    final encryptionKey = await secureStorageService.getHiveKey();
    final boxes = await initHiveBoxes(encryptionKey);
    final prefs = await SharedPreferences.getInstance();

    await _registerDependencies(
      prefs: prefs,
      secureStorageService: secureStorageService,
      boxes: boxes,
    );

    if (E2EMode.enabled) {
      await E2EBootstrap.seedLocalState();
    }
  }

  /// Firebase is used for optional telemetry only, so a failure here is logged
  /// and swallowed rather than blocking startup.
  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e, s) {
      log.warning('Firebase initialization failed: $e\n$s');
    }
  }

  /// Registers every Hive adapter, then opens all boxes encrypted.
  static Future<AppHiveBoxes> initHiveBoxes(List<int> encryptionKey) async {
    log.info('Registering Hive adapters...');
    HiveAdapters.registerAll();
    return AppHiveBoxes.open(encryptionKey);
  }

  static Future<void> _registerDependencies({
    required SharedPreferences prefs,
    required SecureStorageService secureStorageService,
    required AppHiveBoxes boxes,
  }) {
    return initLocator(
      prefs: prefs,
      secureStorageService: secureStorageService,
      expenseBox: boxes.expenseBox,
      accountBox: boxes.accountBox,
      incomeBox: boxes.incomeBox,
      categoryBox: boxes.categoryBox,
      userHistoryBox: boxes.userHistoryBox,
      budgetBox: boxes.budgetBox,
      goalBox: boxes.goalBox,
      contributionBox: boxes.contributionBox,
      recurringRuleBox: boxes.recurringRuleBox,
      recurringRuleAuditLogBox: boxes.recurringRuleAuditLogBox,
      outboxBox: boxes.outboxBox,
      groupBox: boxes.groupBox,
      groupMemberBox: boxes.groupMemberBox,
      groupExpenseBox: boxes.groupExpenseBox,
      profileBox: boxes.profileBox,
    );
  }
}
