import 'dart:async';
import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:expense_tracker/core/sync/services/realtime_service.dart';
import 'package:expense_tracker/core/sync/services/sync_service.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncCoordinator {
  final AuthSessionService _authService;
  final SyncService _syncService;
  final RealtimeService _realtimeService;

  StreamSubscription? _authSubscription;
  StreamSubscription? _connectivitySubscription;

  SyncCoordinator(this._authService, this._syncService, this._realtimeService);

  void initialize() {
    _authSubscription = _authService.onAuthStateChange.listen((state) {
      if (_authService.isAuthenticated) {
        log.info(
          "[SyncCoordinator] User authenticated. Starting sync & realtime.",
        );
        _startSyncLoop();
        _realtimeService.start();
      } else {
        log.info("[SyncCoordinator] User signed out. Stopping realtime.");
        _realtimeService.stop();
      }
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      dynamic results,
    ) {
      // Handle both single (legacy) and list (new) return types dynamically to satisfy analyzer
      bool isConnected = false;
      if (results is List) {
        isConnected = results.any(
          (r) => r.toString() != 'ConnectivityResult.none',
        );
      } else {
        isConnected = results.toString() != 'ConnectivityResult.none';
      }

      if (isConnected && _authService.isAuthenticated) {
        log.info("[SyncCoordinator] Connectivity restored. Triggering sync.");
        _syncService.processOutbox();
      }
    });

    // Initial check
    if (_authService.isAuthenticated) {
      _startSyncLoop();
      _realtimeService.start();
    }
  }

  void _startSyncLoop() {
    _syncService.processOutbox();
  }

  void dispose() {
    _authSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _realtimeService.stop();
  }
}
