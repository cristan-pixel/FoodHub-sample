// lib/services/rider_auth_service.dart
import 'package:foodhub1/models/order_models.dart';
import 'package:foodhub1/services/app_data.dart';
import 'package:foodhub1/services/firebase_sync_service.dart';

/// Auth for the Rider side of the app. Separate from the customer
/// AuthService by design (per your answer) — riders log in on their
/// own screen with their own credential store.
///
/// Demo accounts (seeded in AppData): jun@foodhub.com / rider123,
/// liza@foodhub.com / rider123
class RiderAuthService {
  RiderAuthService._();
  static final RiderAuthService instance = RiderAuthService._();

  final Map<String, String> _passwords = {
    'ace@foodhub.com': 'ace258',
    'jun@foodhub.com': 'rider123',
    'liza@foodhub.com': 'rider123',
  };

  RiderAccount? currentRider;

  /// Pulls rider credentials mirrored in Firestore back into the local
  /// store so an account registered on another device/app-run keeps
  /// working here. Idempotent and never throws (offline is a no-op).
  Future<void> hydrateFromFirestore() async {
    final hashes = await FirebaseSyncService.instance.fetchRiderPasswordHashes();
    if (hashes.isEmpty) return;
    for (final entry in hashes.entries) {
      _passwords[entry.key.trim().toLowerCase()] = entry.value;
    }
  }

  String? register({
    required String name,
    required String email,
    required String password,
    required String vehicle,
  }) {
    final key = email.trim().toLowerCase();
    if (_passwords.containsKey(key)) {
      return 'A rider account with this email already exists.';
    }
    _passwords[key] = password;
    final rider = RiderAccount(
      id: 'd${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: key,
      vehicle: vehicle,
    );
    AppData.instance.registerRider(rider);
    currentRider = rider;
    FirebaseSyncService.instance.upsertRider(rider);
    return null;
  }

  String? login({required String email, required String password}) {
    final key = email.trim().toLowerCase();
    if (!_passwords.containsKey(key)) {
      return 'No rider account found with this email.';
    }
    if (_passwords[key] != password) {
      return 'Incorrect password.';
    }
    final matches = AppData.instance.riders.where((r) => r.email == key);
    if (matches.isNotEmpty) {
      currentRider = matches.first;
    } else {
      // Seeded demo credential with no matching AppData record yet —
      // create one on first login.
      final rider = RiderAccount(
        id: 'd${DateTime.now().millisecondsSinceEpoch}',
        name: key.split('@').first,
        email: key,
        vehicle: 'Motorcycle',
      );
      AppData.instance.registerRider(rider);
      currentRider = rider;
    }
    // Mirror onto the online rider registry (fresh position etc.).
    if (currentRider != null) {
      FirebaseSyncService.instance.upsertRider(currentRider!);
    }
    return null;
  }

  void logout() => currentRider = null;
  bool get isLoggedIn => currentRider != null;
}
