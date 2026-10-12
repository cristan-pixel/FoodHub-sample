// lib/screens/rider/rider_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:foodhub1/models/order_models.dart';
import 'package:foodhub1/services/app_data.dart';
import 'package:foodhub1/services/rider_auth_service.dart';
import 'package:foodhub1/screens/rider/rider_delivery_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rider = RiderAuthService.instance.currentRider;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Text('Hi, ${rider?.name.split(' ').first ?? 'Rider'} 👋',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () {
              RiderAuthService.instance.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/role-select', (route) => false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6600),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF6600),
          tabs: const [
            Tab(text: 'Active Jobs'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: AppData.instance,
        builder: (context, _) {
          final mine = rider == null
              ? <DeliveryOrder>[]
              : AppData.instance.ordersForRider(rider.id);
          final active =
              mine.where((o) => o.status.isActive).toList();
          final history =
              mine.where((o) => !o.status.isActive).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _orderList(
                active,
                emptyText: 'No deliveries assigned to you yet.\n'
                    'The restaurant will assign you an order once the food is ready.',
                builder: (o) => _jobCard(o, isHistory: false),
              ),
              _orderList(
                history,
                emptyText: 'No completed deliveries yet.',
                builder: (o) => _jobCard(o, isHistory: true),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orderList(
    List<DeliveryOrder> orders, {
    required String emptyText,
    required Widget Function(DeliveryOrder) builder,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Text(emptyText,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) => builder(orders[i]),
    );
  }

  Widget _jobCard(DeliveryOrder o, {required bool isHistory}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHistory ? const Color(0xFFE5E7EB) : const Color(0xFFFFE0CC),
          width: isHistory ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.id, style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(o.status.label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFFF6600))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(o.restaurantName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(o.deliveryAddress,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('\u20B1${o.total.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Color(0xFFFF6600), fontWeight: FontWeight.bold)),
          if (o.status.isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => RiderDeliveryScreen(orderId: o.id)),
                ),
                child: const Text('Start Delivery',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}