// lib/services/admin_auth_service.dart

/// Admin accounts are provisioned by you, not self-registered — so
/// this is login-only. Demo credentials: admin@foodhub.com / admin123
///
/// Replace this with real backend-verified auth (and remove the
/// hardcoded password) before shipping.
class AdminAuthService {
  AdminAuthService._();
  static final AdminAuthService instance = AdminAuthService._();

  static const _email = 'admin@foodhub.com';
  static const _password = 'admin123';

  bool _loggedIn = false;
  bool get isLoggedIn => _loggedIn;

  String? login({required String email, required String password}) {
    if (email.trim().toLowerCase() != _email || password != _password) {
      return 'Invalid admin credentials.';
    }
    _loggedIn = true;
    return null;
  }

  void logout() => _loggedIn = false;
}
