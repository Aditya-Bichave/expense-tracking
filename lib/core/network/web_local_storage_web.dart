// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class WebLocalStorage extends LocalStorage {
  final String _key = SupabaseConfig.supabasePersistSessionKey;

  @override
  Future<void> initialize() async {
    log.info('WebLocalStorage initialized. Key: $_key');
    final session = html.window.localStorage[_key];
    log.info('Initial session found: ${session != null}');
  }

  @override
  Future<bool> hasAccessToken() async {
    return html.window.localStorage.containsKey(_key);
  }

  @override
  Future<String?> accessToken() async {
    return html.window.localStorage[_key];
  }

  @override
  Future<void> removePersistedSession() async {
    html.window.localStorage.remove(_key);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    html.window.localStorage[_key] = persistSessionString;
  }
}

LocalStorage getWebLocalStorage() => WebLocalStorage();
