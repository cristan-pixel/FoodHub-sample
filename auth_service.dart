// lib/auth_service.dart
// Customer auth. Accounts are mirrored into Firestore (users collection)
// with a SHA-256 password hash so they survive reinstalls and show up on
// the admin's customer directory; on startup the local store is hydrated
// from the cloud so logins keep working after an app restart.
//
// TODO(optional): move to Firebase Auth for true cross-device logins.
// The screens call these methods synchronously today, so Firebase Auth
// (async) would touch login_screen.dart and signup_screen.dart too.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:foodhub1/services/firebase_sync_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Map of email → SHA-256 password hash
  final Map<String, String> _users = {};

  // Map of email → display name (for admin customer list)
  final Map<String, String> _userNames = {};

  // Currently signed-in user info
  String? currentEmail;
  String? currentName;

  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  /// All registered customers (email + name). Used by the admin
  /// dashboard to show the full user directory.
  List<Map<String, String>> get users => _users.keys
      .map((email) => {
            'email': email,
            'name': _userNames[email] ?? email.split('@').first,
          })
      .toList();

  /// Registers a new user locally and mirrors the account to Firestore so
  /// the admin's directory (and future logins on this device) have it.
  String? register({
    required String name,
    required String email,
    required String password,
  }) {
    final key = email.trim().toLowerCase();
    if (_users.containsKey(key)) {
      return 'An account with this email already exists.';
    }
    _users[key] = _hash(password);
    _userNames[key] = name.trim();
    currentEmail = key;
    currentName = name.trim();
    FirebaseSyncService.instance.upsertUser(
      email: key,
      name: name.trim(),
      passwordHash: _users[key],
    );
    return null; // success
  }

  /// Sign in. Returns null on success, or an error message.
  String? login({
    required String email,
    required String password,
  }) {
    final key = email.trim().toLowerCase();
    if (!_users.containsKey(key)) {
      return 'No account found with this email.';
    }
    if (_users[key] != _hash(password)) {
      return 'Incorrect password.';
    }
    currentEmail = key;
    currentName = _userNames[key] ?? key.split('@').first;
    return null; // success
  }

  /// Updates the signed-in user's display name (email is the login id
  /// and stays fixed) and mirrors the change to Firestore.
  void updateProfile({required String name}) {
    final email = currentEmail;
    if (email == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _userNames[email] = trimmed;
    currentName = trimmed;
    FirebaseSyncService.instance.upsertUser(email: email, name: trimmed);
  }

  /// Pulls registered customers from Firestore into the local store so
  /// accounts persist across restarts. Users whose hash is not stored in
  /// the cloud keep whatever local password they had.
  Future<void> hydrateFromFirestore() async {
    if (!FirebaseSyncService.instance.isEnabled) return;
    final cloudUsers = await FirebaseSyncService.instance.fetchUsers();
    for (final u in cloudUsers) {
      final email = u['email'] ?? '';
      if (email.isEmpty) continue;
      final name = u['name'] ?? email.split('@').first;
      _userNames[email] = name;
      final hash = u['passwordHash'] ?? '';
      if (hash.isNotEmpty) {
        _users[email] = hash;
      }
    }
  }

  bool _usersStreamAttached = false;

  /// Keeps the admin's customer directory live: mirrors the Firestore
  /// users stream into the local store so customers who sign up anywhere
  /// show up without a restart. Safe to call repeatedly; never throws.
  void attachUsersStream() {
    if (_usersStreamAttached) return;
    _usersStreamAttached = true;
    final firebase = FirebaseSyncService.instance;
    if (!firebase.isEnabled) return;
    firebase.streamUsers().listen((cloudUsers) {
      for (final u in cloudUsers) {
        final email = u['email'] ?? '';
        if (email.isEmpty) continue;
        final name = u['name'] ?? email.split('@').first;
        _userNames[email] = name;
        _users.putIfAbsent(email, () => '');
      }
    }, onError: (_) {
      // Stream dropped (offline/rules) — the local store is unaffected.
    });
  }

  void logout() {
    currentEmail = null;
    currentName = null;
  }

  /// The stored SHA-256 hash for an account email (used by the social-auth
  /// mirror so Firestore's user directory always has a consistent hash field,
  /// exactly like the email/password path).
  String? passwordHashFor(String email) =>
      _users[email.trim().toLowerCase()];

  bool get isLoggedIn => currentEmail != null;
}