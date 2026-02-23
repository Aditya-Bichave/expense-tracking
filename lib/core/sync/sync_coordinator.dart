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

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<AuthState>? _authSubscription;

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
        log.info('User logged in. Initializing sync and realtime...');
        _syncService.processOutbox();
        _syncService.initializeRealtime();
      } else {
        log.info('User logged out. Disposing sync services...');
        _realtimeService.unsubscribe();
        _syncService.dispose();
      }
    });

    // Check if already logged in
    if (_client.auth.currentSession != null) {
      log.info('Existing session found. Initializing sync and realtime...');
      _syncService.processOutbox();
      _syncService.initializeRealtime();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _authSubscription?.cancel();
    _realtimeService.unsubscribe();
    _syncService.dispose();
  }
}
