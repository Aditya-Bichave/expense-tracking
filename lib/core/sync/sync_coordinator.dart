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
        _syncService.processOutbox().catchError((e, s) {
          log.severe("Error in processOutbox connectivity listener: $e\n$s");
        });
      }
    });

    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _syncService.processOutbox().catchError((e, s) {
          log.severe("Error in processOutbox auth listener: $e\n$s");
        });
        _syncService.initializeRealtime();
      } else {
        log.info('User logged out. Disposing sync services...');
        _realtimeService.unsubscribe();
        _syncService.dispose();
      }
    });

    // Check if already logged in
    if (_client.auth.currentSession != null) {
      _syncService.processOutbox().catchError((e, s) {
        log.severe("Error in processOutbox initial session check: $e\n$s");
      });
      _syncService.initializeRealtime();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _authSubscription?.cancel();
    _realtimeService.dispose();
    _syncService.dispose();
  }
}
