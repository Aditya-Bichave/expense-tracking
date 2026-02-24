import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense_tracker/core/sync/realtime_service.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class SyncCoordinator {
  final SyncService _syncService;
  final RealtimeService _realtimeService;
  final Connectivity _connectivity;
  final SupabaseClient _client;

  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _authSubscription;

  SyncCoordinator(
    this._syncService,
    this._realtimeService,
    this._connectivity,
    this._client,
  );

  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        log.info('Network connected. Processing outbox...');
        _syncService.processOutbox();
      }
    });

    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        log.info('User logged in. Initializing sync...');
        _syncService.processOutbox();
      } else {
        _realtimeService.unsubscribe();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _authSubscription?.cancel();
    _realtimeService.unsubscribe();
  }
}
