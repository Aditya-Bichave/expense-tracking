import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';

class AuthSessionService {
  final SupabaseClient _client;
  final BehaviorSubject<User?> _userController;

  AuthSessionService(this._client)
    : _userController = BehaviorSubject<User?>.seeded(
        _client.auth.currentUser,
      ) {
    _client.auth.onAuthStateChange.listen((data) {
      _userController.add(data.session?.user);
    });
  }

  Stream<User?> get userStream => _userController.stream;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  void dispose() {
    _userController.close();
  }
}
