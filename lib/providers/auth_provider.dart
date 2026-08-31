import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({this.shopId});

  final String? shopId;

  bool get isLoggedIn => shopId != null;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  /// Temporary local login. Supabase Auth replaces this in a later step.
  String? login(String id, String password) {
    if (id.trim().isEmpty || password.isEmpty) {
      return 'ID aur password likho';
    }
    state = AuthState(shopId: id.trim());
    return null;
  }

  void logout() => state = const AuthState();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
