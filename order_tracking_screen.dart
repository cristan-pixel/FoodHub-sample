// lib/screens/order_tracking_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foodhub1/models/order_models.dart';
import 'package:foodhub1/services/app_data.dart';
import 'package:foodhub1/services/firebase_sync_service.dart';
import 'package:foodhub1/widgets/live_order_map.dart';

class OrderTrackingScreen extends StatefulWidget {
  final double totalAmount;
  final String deliveryTime;
  final String orderSummary;
  final String orderNumber;
  final String deliveryAddress;
  final String paymentMethod;

  const OrderTrackingScreen({
    super.key,
    required this.totalAmount,
    required this.deliveryTime,
    required this.orderSummary,
    required this.orderNumber,
    required this.deliveryAddress,
    required this.paymentMethod,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late TextEditingController _addressController;
  late final Stream<OrderSnapshot?> _orderStream;
  StreamSubscription<OrderSnapshot?>? _orderSub;
  OrderStatus? _streamStatus;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.deliveryAddress);
    _orderStream = FirebaseSyncService.instance.streamOrder(widget.orderNumber);
    _orderSub = _orderStream.listen((snap) {
      if (snap == null || !mounted) return;
      setState(() => _streamStatus = snap.status);
    }, onError: (_) {
      // Offline / rules deny read — the tracker falls back to AppData.
    });
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  /// Maps the real order lifecycle (live Firestore status first, AppData
  /// as fallback) to the 4 visual steps, so the tracker keeps advancing
  /// even if the local store hasn't re-hydrated yet.
  int get _stepFromStatus {
    final status =
        _streamStatus ?? AppData.instance.orderById(widget.orderNumber)?.status;
    if (status == null) return 0;
    switch (status) {
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.riderAssigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return 2;
      case OrderStatus.readyForPickup:
        return 1;
      case OrderStatus.placed:
      case OrderStatus.restaurantAccepted:
      case OrderStatus.preparing:
        return 0;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Order Tracking",
          style: TextStyle(color: Color(0xFF1A1D26), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order #${widget.orderNumber}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.orderSummary,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "\u20B1${widget.totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Delivery Address Label
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          "Delivery Address",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Plain text typing field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFEE7D6)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: TextField(
                        controller: _addressController,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        maxLines: 2,
                        minLines: 1,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: "e.g. Purok 3, Poblacion, Tangub City",
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          // Address updates live as the user types
                        },
                      ),
                    ),

                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.credit_card_outlined, widget.paymentMethod),
                    const Divider(height: 24, color: Color(0xFFFEE7D6)),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Color(0xFFFF6600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Estimated arrival: ${widget.deliveryTime}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D26),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Live GPS tracking map ─────────────────────────────
              // Shows once AppData has this order (i.e. it went through
              // the normal checkout flow) and rebuilds live as the
              // rider's GPS location updates.
              AnimatedBuilder(
                animation: AppData.instance,
                builder: (context, _) {
                  final order = AppData.instance.orderById(widget.orderNumber);
                  // Show the tracker as long as the order exists locally
                  // OR the Firestore document is streaming (survives
                  // logout/restart before AppData re-hydrates).
                  if (order == null && _streamStatus == null) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_searching,
                              size: 16, color: Color(0xFFFF6600)),
                          const SizedBox(width: 6),
                          Text(
                            (_streamStatus ?? order?.status)?.label ??
                                'Order Placed',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Streams the same Firestore order document
                      // (orders/{orderId}) so the rider marker and status
                      // badge update live; falls back to in-memory AppData
                      // when Firebase is unavailable.
                      LiveOrderMap(
                        orderId: widget.orderNumber,
                        height: 200,
                        orderStream: _orderStream,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Tracking Steps — rebuild live with the real order status
              AnimatedBuilder(
                animation: AppData.instance,
                builder: (context, _) {
                  final currentStep = _stepFromStatus;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStep(
                        icon: Icons.access_time_filled,
                        title: "Preparing",
                        subtitle: "Restaurant is preparing your order",
                        stepIndex: 0,
                        currentStep: currentStep,
                      ),
                      _buildStep(
                        icon: Icons.inventory_2_outlined,
                        title: "Ready for Pickup",
                        subtitle: "Order is packed and ready",
                        stepIndex: 1,
                        currentStep: currentStep,
                      ),
                      _buildStep(
                        icon: Icons.local_shipping_outlined,
                        title: "On the Way",
                        subtitle: "Driver is heading to your address",
                        stepIndex: 2,
                        currentStep: currentStep,
                      ),
                      _buildStep(
                        icon: Icons.home_outlined,
                        title: "Delivered",
                        subtitle: "Enjoy your meal!",
                        stepIndex: 3,
                        currentStep: currentStep,
                        isLast: true,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F2F4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required int stepIndex,
    required int currentStep,
    bool isLast = false,
  }) {
    final bool isCompleted = stepIndex <= currentStep;
    final bool isActive = stepIndex == currentStep;

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF00C566) : const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? const Color(0xFF00C566) : const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.black : Colors.grey[400],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6600),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "In progress",
                          style: TextStyle(
                            color: Color(0xFFFF6600),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}