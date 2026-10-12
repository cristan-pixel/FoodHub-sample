// lib/services/route_service.dart
//
// Fetches real road routes for the live map using the free public OSRM
// routing API (https://project-osrm.org) and decodes the returned
// polyline with flutter_polyline_points. No API key required, which
// keeps the demo self-contained. Every lookup is cached and all
// failures return null so the map can keep drawing a straight-line
// approximation until a road route is available (or offline).

import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:foodhub1/models/order_models.dart' as models;

class RouteService {
  RouteService._();
  static final RouteService instance = RouteService._();

  /// Minimum gap between actual network round-trips, so rapid GPS fixes
  /// don't hammer the routing server.
  static const Duration _minFetchInterval = Duration(seconds: 10);

  /// How long a failed/empty lookup stays cached so we don't immediately
  /// re-request the same dead route on every marker move.
  static const Duration _nullCacheTtl = Duration(seconds: 30);

  static const Duration _requestTimeout = Duration(seconds: 15);

  final Map<String, List<models.GeoPoint>?> _cache = {};
  final Map<String, DateTime> _cacheAt = {};
  DateTime _lastFetchAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Cache key rounds coordinates so near-identical origin/destination
  /// pairs (rider jitter) reuse the same route.
  String _key(models.GeoPoint origin, models.GeoPoint destination) {
    String r(double v) => v.toStringAsFixed(4); // ~11m precision
    return '${r(origin.lat)},${r(origin.lng)}|${r(destination.lat)},${r(destination.lng)}';
  }

  /// Returns the road-route polyline between [origin] and [destination],
  /// or null when routing is unavailable. Caches results per leg.
  Future<List<models.GeoPoint>?> route({
    required models.GeoPoint origin,
    required models.GeoPoint destination,
  }) async {
    final key = _key(origin, destination);
    final cached = _cache[key];
    if (cached != null) return cached;
    final cachedAt = _cacheAt[key];
    final now = DateTime.now();
    if (cachedAt != null && now.difference(cachedAt) < _nullCacheTtl) {
      return cached; // still within the negative-cache window
    }
    _cacheAt[key] = now;

    // Throttle actual HTTP requests.
    if (now.difference(_lastFetchAt) < _minFetchInterval) return cached;
    _lastFetchAt = now;

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.lng},${origin.lat};${destination.lng},${destination.lat}'
        '?overview=full&geometries=polyline',
      );
      final res = await http.get(uri).timeout(_requestTimeout);
      if (res.statusCode != 200) {
        _cache[key] = null;
        return null;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) {
        _cache[key] = null;
        return null;
      }
      final geometry =
          (routes.first as Map<String, dynamic>)['geometry'] as String?;
      if (geometry == null) {
        _cache[key] = null;
        return null;
      }
      final points = PolylinePoints.decodePolyline(geometry)
          .map((p) => models.GeoPoint(p.latitude, p.longitude))
          .toList();
      if (points.length < 2) {
        _cache[key] = null;
        return null;
      }
      _cache[key] = points;
      return points;
    } catch (_) {
      // Offline / routing service down / invalid response — never crash
      // the map, just fall back to the straight line.
      _cache[key] = null;
      return null;
    }
  }
}