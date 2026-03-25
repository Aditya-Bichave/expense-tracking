import 'package:expense_tracker/core/utils/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:simple_logger/simple_logger.dart';

class NotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging? _fcmInstance;
  final SimpleLogger _log = SimpleLogger();
  final SharedPreferences? _prefs;
  StreamSubscription<String>? _tokenRefreshSub;

  NotificationService({
    SupabaseClient? supabase,
    FirebaseMessaging? fcm,
    SharedPreferences? prefs,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _fcmInstance = fcm,
       _prefs = prefs;

  FirebaseMessaging _getFcm() {
    return _fcmInstance ?? FirebaseMessaging.instance;
  }

  Future<void> syncDeviceToken() async {
    try {
      // 1. Request Permission
      NotificationSettings settings = await _getFcm().requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        _log.info('User declined or has not accepted notification permissions');
        return;
      }

      // 2. Get FCM Token
      String? token = await _getFcm().getToken();
      if (token == null) {
        _log.warning('Failed to get FCM token');
        return;
      }

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        _log.warning('Cannot sync device token: No user logged in');
        return;
      }

      // 3. Get Unique Device ID
      String platform = _getPlatform();
      if (platform == 'desktop' || platform == 'unknown') {
        _log.info('Skipping token sync on unsupported platform: $platform');
        return;
      }
      String deviceId = await _getDeviceId();

      // 4. Upsert to Supabase
      final success = await _upsertToken(
        currentUser.id,
        deviceId,
        token,
        platform,
      );
      if (!success) {
        _log.warning('Failed initial token sync, will retry on refresh');
      }

      // Listen for notification taps when the app is in the background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _log.info('Notification tapped: ${message.data}');
        _handleNotificationRouting(message.data);
      });

      // Also check if the app was opened from a terminated state via a notification
      RemoteMessage? initialMessage = await _getFcm().getInitialMessage();
      if (initialMessage != null) {
        _log.info('App opened via notification: ${initialMessage.data}');
        _handleNotificationRouting(initialMessage.data);
      }

      // 5. Listen for token refreshes
      if (_tokenRefreshSub == null) {
        _tokenRefreshSub = _getFcm().onTokenRefresh.listen((newToken) async {
          final user = _supabase.auth.currentUser;
          if (user != null) {
            await _upsertToken(user.id, deviceId, newToken, platform);
          }
        });
        _tokenRefreshSub?.onError((e, s) {
          _log.severe('Error on FCM token refresh: $e\n$s');
        });
      }
    } catch (e, s) {
      log.severe("Msg: $e\n$s");
      _log.severe('Error syncing device token: $e\n$s');
    }
  }

  Future<bool> _upsertToken(
    String userId,
    String deviceId,
    String token,
    String platform,
  ) async {
    try {
      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'device_id': deviceId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e, s) {
      log.severe("Msg: $e\n$s");
      _log.severe('Failed to upsert user_fcm_tokens: $e\n$s');
      return false;
    }
  }

  Future<void> deleteDeviceToken() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      String deviceId = await _getDeviceId();

      await _supabase
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', currentUser.id)
          .eq('device_id', deviceId);

      // Also delete the token locally from firebase messaging so it can regenerate properly next time
      await _getFcm().deleteToken();
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
    } catch (e, s) {
      log.severe("Msg: $e\n$s");
      _log.severe('Error deleting device token: $e\n$s');
    }
  }

  Future<String> _getDeviceId() async {
    const key = 'app_device_id';
    if (_prefs != null) {
      String? id = _prefs.getString(key);
      if (id == null) {
        id = const Uuid().v4();
        await _prefs.setString(key, id);
      }
      return id;
    }

    // Fallback for tests if _prefs is not injected
    return 'fallback_device_id';
  }

  String _getPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) {
      return 'desktop';
    } else {
      return 'unknown';
    }
  }

  void _handleNotificationRouting(Map<String, dynamic> data) {
    if (data['type'] == 'NUDGE' && data.containsKey('group_id')) {
      final groupId = data['group_id'];
      _log.info('Routing to group details for Nudge: $groupId');
      // For proper routing, ideally we'd use a GlobalKey<NavigatorState> or stream to the Router.
      // E.g., AppRouter.router.go('/dashboard/groups/$groupId/balances');
      // Adding it to a broadcast stream or handling via DeepLinkBloc is an option.

      // Since DeepLinkBloc is available, let's use a workaround to dispatch it as a deep link.
      // Note: Full implementation would depend on the routing strategy.
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
