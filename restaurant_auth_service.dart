// lib/services/restaurant_auth_service.dart
import 'package:foodhub1/models/order_models.dart';
import 'package:foodhub1/services/app_data.dart';
import 'package:foodhub1/services/firebase_sync_service.dart';

/// Auth for the Restaurant-partner side of the app.
///
/// Demo accounts (all password `rest123`):
///  jb@foodhub.com        → JB LutongBahay Resto
///  bibiana@foodhub.com   → Bibiana FoodHouse
///  mamos@foodhub.com     → Mamos Tasty Ramen
///  pareng@foodhub.com    → Pareng Eling
///  pastilan@foodhub.com  → Pastilan
class RestaurantAuthService {
  RestaurantAuthService._();
  static final RestaurantAuthService instance = RestaurantAuthService._();

  final Map<String, String> _passwords = {
    'jb@foodhub.com': 'rest123',
    'bibiana@foodhub.com': 'rest123',
    'mamos@foodhub.com': 'rest123',
    'pareng@foodhub.com': 'rest123',
    'pastilan@foodhub.com': 'rest123',
  };

  RestaurantAccount? currentRestaurant;

  /// Pulls restaurant-partner credentials mirrored in Firestore back into
  /// the local store so an account registered on another device/app-run
  /// keeps working here. Idempotent and never throws.
  Future<void> hydrateFromFirestore() async {
    final hashes =
        await FirebaseSyncService.instance.fetchRestaurantPasswordHashes();
    if (hashes.isEmpty) return;
    for (final entry in hashes.entries) {
      _passwords[entry.key.trim().toLowerCase()] = entry.value;
    }
  }

  String? register({
    required String name,
    required String email,
    required String password,
    required String cuisine,
    required String address,
  }) {
    final key = email.trim().toLowerCase();
    if (_passwords.containsKey(key)) {
      return 'A restaurant account with this email already exists.';
    }
    _passwords[key] = password;
    final restaurant = RestaurantAccount(
      id: 'rest${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: key,
      cuisine: cuisine,
      address: address,
      // New partners default near the delivery city center (Tangub
      // City); in production geocode `address` instead.
      location: const GeoPoint(8.0660, 123.7480),
    );
    AppData.instance.registerRestaurant(restaurant);
    currentRestaurant = restaurant;
    FirebaseSyncService.instance.upsertRestaurant(restaurant);
    return null;
  }

  String? login({required String email, required String password}) {
    final key = email.trim().toLowerCase();
    if (!_passwords.containsKey(key)) {
      return 'No restaurant account found with this email.';
    }
    if (_passwords[key] != password) {
      return 'Incorrect password.';
    }
    final matches = AppData.instance.restaurants.where((r) => r.email == key);
    currentRestaurant = matches.isNotEmpty ? matches.first : null;
    // Mirror onto the online partner registry.
    if (currentRestaurant != null) {
      FirebaseSyncService.instance.upsertRestaurant(currentRestaurant!);
    }
    return null;
  }

  void logout() => currentRestaurant = null;
  bool get isLoggedIn => currentRestaurant != null;
}
