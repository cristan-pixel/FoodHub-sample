// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:foodhub1/auth_service.dart';
import 'package:foodhub1/models/order_models.dart' as models;
import 'package:foodhub1/services/admin_auth_service.dart';
import 'package:foodhub1/services/app_data.dart';
import 'package:latlong2/latlong.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D26),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Admin — FoodHub Ops',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              AdminAuthService.instance.logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/role-select', (route) => false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6600),
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFFF6600),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Orders'),
            Tab(text: 'Restaurants'),
            Tab(text: 'Customers'),
            Tab(text: 'Live Map'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: AppData.instance,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _overviewTab(),
              _ordersTab(),
              _restaurantsRidersTab(),
              _customersTab(),
              _liveMapTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _overviewTab() {
    final data = AppData.instance;
    final stats = [
      ('Active Orders', data.activeOrderCount.toString(), Icons.local_shipping_outlined),
      ('Delivered Today', data.deliveredTodayCount.toString(), Icons.check_circle_outline),
      ('Restaurants', data.restaurants.length.toString(), Icons.storefront_outlined),
      ('Riders', data.riders.length.toString(), Icons.two_wheeler),
      ('Total Revenue', '\u20B1${data.totalRevenue.toStringAsFixed(2)}', Icons.payments_outlined),
    ];
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: stats
          .map((s) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(s.$3, color: const Color(0xFFFF6600)),
                    const Spacer(),
                    Text(s.$2,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(s.$1,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _ordersTab() {
    final orders = AppData.instance.orders;
    if (orders.isEmpty) {
      return const Center(child: Text('No orders yet.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${o.id} · ${o.restaurantName}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(o.orderSummary,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (o.assignedRiderName != null)
                      Text('Rider: ${o.assignedRiderName}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\u20B1${o.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: o.status == models.OrderStatus.delivered
                          ? Colors.green.shade50
                          : o.status == models.OrderStatus.cancelled
                              ? Colors.red.shade50
                              : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(o.status.label,
                        style: TextStyle(
                            fontSize: 11,
                            color: o.status == models.OrderStatus.delivered
                                ? Colors.green.shade700
                                : o.status == models.OrderStatus.cancelled
                                    ? Colors.red.shade700
                                    : const Color(0xFFFF6600))),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _restaurantsRidersTab() {
    final restaurants = AppData.instance.restaurants;
    final riders = AppData.instance.riders;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Restaurants',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...restaurants.map((r) => ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE5E7EB))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              leading: const Icon(Icons.storefront, color: Color(0xFFFF6600)),
              title: Text(r.name),
              subtitle: Text('${r.cuisine} · ${r.address}'),
            )),
        const SizedBox(height: 20),
        const Text('Riders',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...riders.map((r) => ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE5E7EB))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              leading: const Icon(Icons.two_wheeler, color: Color(0xFFFF6600)),
              title: Text(r.name),
              subtitle: Text(r.vehicle),
              trailing: Icon(Icons.circle,
                  size: 10, color: r.online ? Colors.green : Colors.grey),
            )),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _customersTab() {
    final users = AuthService.instance.users;
    final orders = AppData.instance.orders;

    if (users.isEmpty) {
      return const Center(
          child: Text('No registered customers yet.',
              style: TextStyle(color: Colors.grey)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: users.map((u) {
        final email = u['email'] ?? '';
        final myOrders =
            orders.where((o) => o.customerEmail == email).toList();
        final spend = myOrders.fold<double>(
            0.0, (sum, o) => sum + (o.status == models.OrderStatus.cancelled ? 0 : o.total));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.person_outline, color: Color(0xFFFF6600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(email,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${myOrders.length} order(s)',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Text('\u20B1${spend.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Color(0xFFFF6600), fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _liveMapTab() {
    final active = AppData.instance.orders.where((o) => o.status.isActive).toList();

    final markers = <Marker>[];
    for (final r in AppData.instance.restaurants) {
      markers.add(Marker(
        point: LatLng(r.location.lat, r.location.lng),
        child: _mapPin(const Color(0xFFFF6600), Icons.storefront_outlined),
      ));
    }
    for (final o in active) {
      markers.add(Marker(
        point: LatLng(o.customerLocation.lat, o.customerLocation.lng),
        child: _mapPin(const Color(0xFF1E88E5), Icons.home_outlined),
      ));
      if (o.riderLocation != null) {
        markers.add(Marker(
          point: LatLng(o.riderLocation!.lat, o.riderLocation!.lng),
          width: 38,
          height: 38,
          child: _mapPin(const Color(0xFF00C566), Icons.bolt, isLive: true),
        ));
      }
    }

    final center = markers.isNotEmpty
        ? markers.first.point
        : const LatLng(8.0659, 123.7477); // Tangub City center

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFFFF3E0),
          child: Text(
            '${active.length} active order(s) · orange = restaurant, green = rider (live GPS), blue = delivery address',
            style: const TextStyle(fontSize: 12, color: Colors.brown),
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12,
              backgroundColor: const Color(0xFFE8EAED),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodhub.app',
              ),
              MarkerLayer(markers: markers),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapPin(Color color, IconData icon, {bool isLive = false}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          if (isLive)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
