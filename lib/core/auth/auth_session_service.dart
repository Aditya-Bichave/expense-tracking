import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSessionService {
  final SupabaseClient _client;
  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();
  late final StreamSubscription<AuthState> _authSubscription;

  AuthSessionService(this._client) {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
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
    _authSubscription.cancel();
    _userController.close();
  }
}
