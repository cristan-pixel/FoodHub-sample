// lib/widgets/profile_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodhub1/auth_service.dart';
import 'package:foodhub1/menu_items.dart';
import 'package:foodhub1/widgets/restaurant_menu_sheet.dart';

class ProfileSheet extends StatefulWidget {
  final String address;
  final String paymentMethod;
  final List<Map<String, String>> allRestaurants;
  // FIX: orderHistory is now properly passed from HomePage
  final List<Map<String, dynamic>> orderHistory;
  final Function(String) onUpdateAddress;
  final Function(String) onUpdatePayment;
  final ScrollController scrollController;

  // ── Favorites wired from HomePage ──────────────────────────
  final Set<String> favoriteNames;
  final Function(String) onToggleFavorite;

  // FIX: "Order Now" in Favorites tab triggers cart logic in HomePage
  final Function(Map<String, String>) onOrderFromFavorites;

  const ProfileSheet({
    super.key,
    required this.address,
    required this.allRestaurants,
    required this.onUpdateAddress,
    required this.onUpdatePayment,
    required this.scrollController,
    required this.favoriteNames,
    required this.onToggleFavorite,
    required this.onOrderFromFavorites,
    this.paymentMethod = 'GCash',
    this.orderHistory = const [],
  });

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Profile ────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  // ── Loyalty ────────────────────────────────────────────────
  int _loyaltyPoints = 320;

  // ── Notifications ──────────────────────────────────────────
  bool _notifOrders    = true;
  bool _notifPromos    = true;
  bool _notifDelivery  = true;
  bool _notifEmail     = false;

  // ── Addresses ──────────────────────────────────────────────
  late List<Map<String, String>> _addresses;

  // ── Payment Methods ────────────────────────────────────────
  late List<Map<String, String>> _payments;

  // ── Referral ───────────────────────────────────────────────
  final String _referralCode = 'FOODHUB2025';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));

    final auth = AuthService.instance;
    _nameCtrl  = TextEditingController(text: auth.currentName ?? 'Guest');
    _emailCtrl = TextEditingController(text: auth.currentEmail ?? '');
    _phoneCtrl = TextEditingController(text: '');

    _addresses = [
      {'label': 'Home', 'address': widget.address, 'isDefault': 'true'},
      {'label': 'Work', 'address': 'Misamis University, Ozamiz City', 'isDefault': 'false'},
    ];

    _payments = [
      {'type': 'GCash', 'detail': 'linked', 'isDefault': 'true'},
      {'type': 'Cash on Delivery', 'detail': 'always available', 'isDefault': 'false'},
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _favorites => widget.allRestaurants
      .where((r) => widget.favoriteNames.contains(r['name']))
      .toList();

  void _snack(String msg, {Color bg = const Color(0xFFFF6600)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFFF6600),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF6600),
          indicatorWeight: 2.5,
          tabAlignment: TabAlignment.start,
          tabs: [
            _tab(Icons.person_outline, 'Profile'),
            _tab(Icons.star_border_rounded, 'Loyalty'),
            _tab(Icons.favorite_border, 'Favorites'),
            _tab(Icons.location_on_outlined, 'Addresses'),
            _tab(Icons.settings_outlined, 'Settings'),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(),
              _buildLoyaltyTab(),
              _buildFavoritesTab(),
              _buildAddressesTab(),
              _buildSettingsTab(),
            ],
          ),
        ),
      ]),
    );
  }

  Tab _tab(IconData icon, String label) => Tab(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 13)),
        ]),
      );

  // ═══════════════════════════════════════════════════════════
  //  TAB 1 — PROFILE
  // ═══════════════════════════════════════════════════════════
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6600), Color(0xFFFF8C42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Stack(alignment: Alignment.bottomRight, children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 44, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_outlined,
                    size: 14, color: Color(0xFFFF6600)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              _nameCtrl.text.trim().isEmpty ? 'Guest User' : _nameCtrl.text.trim(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(_emailCtrl.text.trim(),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Text('$_loyaltyPoints pts',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        _inputField('Full Name', _nameCtrl),
        const SizedBox(height: 14),
        _inputField('Email Address', _emailCtrl,
            type: TextInputType.emailAddress, readOnly: true),
        const SizedBox(height: 14),
        _inputField('Phone Number', _phoneCtrl, type: TextInputType.phone),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE0CC)),
          ),
          child: Row(children: [
            const Icon(Icons.card_giftcard, color: Color(0xFFFF6600)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your Referral Code',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(_referralCode,
                    style: const TextStyle(
                        color: Color(0xFFFF6600),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
                const Text('Share & earn 50 pts per friend',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Color(0xFFFF6600)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _referralCode));
                _snack('Referral code copied!');
              },
            ),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) {
                _snack('Name cannot be empty', bg: Colors.red);
                return;
              }
              AuthService.instance.updateProfile(name: name);
              _snack('Profile updated!', bg: Colors.green);
            },
            child: const Text('Save Changes',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        AuthService.instance.logout();
                        // Close the dialog + sheet, then land on the
                        // customer login page with a cleared stack.
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                      child: const Text('Sign Out',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text, bool readOnly = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1D26))),
      const SizedBox(height: 7),
      TextField(
        controller: ctrl,
        keyboardType: type,
        readOnly: readOnly,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6600), width: 1.5)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 2 — LOYALTY
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoyaltyTab() {
    const int nextTier = 500;
    final double progress = (_loyaltyPoints / nextTier).clamp(0.0, 1.0);
    final String tier = _loyaltyPoints >= 500
        ? 'Gold'
        : _loyaltyPoints >= 200
            ? 'Silver'
            : 'Bronze';
    final Color tierColor = tier == 'Gold'
        ? Colors.amber
        : tier == 'Silver'
            ? Colors.blueGrey
            : const Color(0xFFCD7F32);

    final List<Map<String, dynamic>> rewards = [
      {'title': 'Free Delivery', 'pts': 100, 'icon': Icons.delivery_dining},
      {'title': '\u20B15 Voucher',   'pts': 200, 'icon': Icons.card_giftcard},
      {'title': '\u20B110 Voucher',  'pts': 400, 'icon': Icons.local_offer},
      {'title': 'Free Dessert',  'pts': 150, 'icon': Icons.cake},
      {'title': '20% Off Order', 'pts': 300, 'icon': Icons.percent},
    ];

    final List<Map<String, dynamic>> history = [
      {'desc': 'Order #ORD-12345',        'pts': '+25',  'date': 'Today',       'add': true},
      {'desc': 'Referral Bonus',           'pts': '+50',  'date': 'Yesterday',   'add': true},
      {'desc': 'Redeemed Free Delivery',   'pts': '-100', 'date': '3 days ago',  'add': false},
      {'desc': 'Order #ORD-11290',         'pts': '+20',  'date': '5 days ago',  'add': true},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tierColor.withValues(alpha: 0.9), tierColor],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text('$tier Member',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$_loyaltyPoints',
                style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, height: 1)),
            const Text('POINTS',
                style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text('${(nextTier - _loyaltyPoints).clamp(0, nextTier)} pts to next tier',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),

        const SizedBox(height: 24),
        _sectionLabel('Redeem Rewards'),
        const SizedBox(height: 12),

        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rewards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final r = rewards[i];
              final canRedeem = _loyaltyPoints >= (r['pts'] as int);
              return GestureDetector(
                onTap: canRedeem
                    ? () {
                        setState(() => _loyaltyPoints -= r['pts'] as int);
                        _snack('Redeemed: ${r['title']}!', bg: Colors.green);
                      }
                    : () => _snack('Not enough points', bg: Colors.grey),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: canRedeem ? const Color(0xFFFFF7F0) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: canRedeem ? const Color(0xFFFFE0CC) : Colors.grey.shade200),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(r['icon'] as IconData,
                        color: canRedeem ? const Color(0xFFFF6600) : Colors.grey, size: 24),
                    const SizedBox(height: 6),
                    Text(r['title'] as String,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: canRedeem ? Colors.black : Colors.grey),
                        textAlign: TextAlign.center, maxLines: 2),
                    const SizedBox(height: 4),
                    Text('${r['pts']} pts',
                        style: TextStyle(
                            fontSize: 11,
                            color: canRedeem ? const Color(0xFFFF6600) : Colors.grey,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
        _sectionLabel('Points History'),
        const SizedBox(height: 12),

        ...history.map((h) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (h['add'] as bool)
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (h['add'] as bool) ? Icons.add : Icons.remove,
                    size: 14,
                    color: (h['add'] as bool) ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h['desc'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(h['date'] as String,
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ]),
                ),
                Text(h['pts'] as String,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: (h['add'] as bool) ? Colors.green : Colors.red)),
              ]),
            )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 3 — FAVORITES
  // FIX: "Order Now" now properly calls back to HomePage cart logic
  // ═══════════════════════════════════════════════════════════
  Widget _buildFavoritesTab() {
    final favs = _favorites;

    if (favs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No favorites yet',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Tap the ❤ on a restaurant to save it here',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, i) {
        final r = favs[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              // FIX: load first menu image for the restaurant
              Builder(builder: (_) {
                final List items = restaurantMenus[r['name']] ?? [];
                final String imgUrl =
                    items.isNotEmpty ? (items.first['image'] ?? '') : '';
                return ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: imgUrl.isNotEmpty
                        ? Image.asset(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: Icon(Icons.fastfood_rounded,
                                  color:
                                      Colors.orange.withValues(alpha: 0.4),
                                  size: 36),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: Icon(Icons.fastfood_rounded,
                                color: Colors.orange.withValues(alpha: 0.4),
                                size: 36),
                          ),
                  ),
                );
              }),
              // Unfavorite button
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: () {
                    widget.onToggleFavorite(r['name']!);
                    setState(() {});
                    _snack('Removed from favorites');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_rounded,
                        color: Color(0xFFFF6600), size: 16),
                  ),
                ),
              ),
              // Rating badge
              Positioned(
                bottom: 6, left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 12),
                    const SizedBox(width: 2),
                    Text(r['rating'] ?? '0.0',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.orange)),
                  ]),
                ),
              ),
            ]),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(r['tags'] ?? '',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text('${r['prep']} min',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ]),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      // Opens the restaurant menu; ordering happens per item.
                      onPressed: () => openRestaurantMenu(
                        context,
                        r,
                        widget.onOrderFromFavorites,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6600),
                        side: const BorderSide(
                            color: Color(0xFFFF6600), width: 1.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Menu',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 4 — ADDRESSES
  // ═══════════════════════════════════════════════════════════
  Widget _buildAddressesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GestureDetector(
          onTap: _showAddAddressDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFF6600), width: 1.5),
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFFFF7F0),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_location_alt_outlined, color: Color(0xFFFF6600), size: 20),
              SizedBox(width: 8),
              Text('Add New Address',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFFFF6600))),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        ..._addresses.asMap().entries.map((entry) {
          final i = entry.key;
          final addr = entry.value;
          final isDefault = addr['isDefault'] == 'true';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDefault ? const Color(0xFFFFF7F0) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDefault ? const Color(0xFFFF6600) : Colors.transparent,
                  width: 1.5),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDefault
                      ? const Color(0xFFFF6600).withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  addr['label'] == 'Home'
                      ? Icons.home_outlined
                      : addr['label'] == 'Work'
                          ? Icons.work_outline
                          : Icons.location_on_outlined,
                  color: isDefault ? const Color(0xFFFF6600) : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(addr['label'] ?? 'Address',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFF6600),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('Default',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(addr['address'] ?? '',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  if (!isDefault) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          for (var a in _addresses) {
                            a['isDefault'] = 'false';
                          }
                          _addresses[i]['isDefault'] = 'true';
                          widget.onUpdateAddress(_addresses[i]['address']!);
                        });
                        _snack('Default address updated');
                      },
                      child: const Text('Set as default',
                          style: TextStyle(
                              color: Color(0xFFFF6600),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
              ),
              Column(children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: Colors.grey.shade500,
                  onPressed: () => _showEditAddressDialog(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red.shade300,
                  onPressed: () => setState(() => _addresses.removeAt(i)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ]),
          );
        }),
      ],
    );
  }

  void _showAddAddressDialog() {
    final labelCtrl = TextEditingController();
    final addrCtrl  = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: labelCtrl,
            decoration: InputDecoration(
                labelText: 'Label (Home, Work, etc.)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: addrCtrl,
            maxLines: 2,
            decoration: InputDecoration(
                labelText: 'Full Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6600)),
            onPressed: () {
              if (addrCtrl.text.trim().isNotEmpty) {
                setState(() => _addresses.add({
                  'label': labelCtrl.text.trim().isEmpty ? 'Address' : labelCtrl.text.trim(),
                  'address': addrCtrl.text.trim(),
                  'isDefault': 'false',
                }));
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditAddressDialog(int index) {
    final labelCtrl = TextEditingController(text: _addresses[index]['label']);
    final addrCtrl  = TextEditingController(text: _addresses[index]['address']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: labelCtrl,
            decoration: InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: addrCtrl,
            maxLines: 2,
            decoration: InputDecoration(
                labelText: 'Full Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6600)),
            onPressed: () {
              setState(() {
                _addresses[index] = {
                  ..._addresses[index],
                  'label': labelCtrl.text.trim().isEmpty
                      ? _addresses[index]['label']!
                      : labelCtrl.text.trim(),
                  'address': addrCtrl.text.trim().isEmpty
                      ? _addresses[index]['address']!
                      : addrCtrl.text.trim(),
                };
                if (_addresses[index]['isDefault'] == 'true') {
                  widget.onUpdateAddress(_addresses[index]['address']!);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 5 — SETTINGS
  // ═══════════════════════════════════════════════════════════
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Notifications'),
        const SizedBox(height: 10),
        _switchTile(
          icon: Icons.receipt_long_outlined, iconColor: const Color(0xFFFF6600),
          title: 'Order Updates', subtitle: 'Status changes for your orders',
          value: _notifOrders, onChanged: (v) => setState(() => _notifOrders = v),
        ),
        _switchTile(
          icon: Icons.local_shipping_outlined, iconColor: Colors.blue,
          title: 'Delivery Alerts', subtitle: 'When your rider is nearby',
          value: _notifDelivery, onChanged: (v) => setState(() => _notifDelivery = v),
        ),
        _switchTile(
          icon: Icons.local_offer_outlined, iconColor: Colors.purple,
          title: 'Promos & Offers', subtitle: 'Exclusive deals and discounts',
          value: _notifPromos, onChanged: (v) => setState(() => _notifPromos = v),
        ),
        _switchTile(
          icon: Icons.email_outlined, iconColor: Colors.teal,
          title: 'Email Newsletter', subtitle: 'Weekly deals sent to your email',
          value: _notifEmail, onChanged: (v) => setState(() => _notifEmail = v),
        ),

        const SizedBox(height: 24),
        _sectionLabel('Payment Methods'),
        const SizedBox(height: 10),
        ..._payments.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isDefault = p['isDefault'] == 'true';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDefault ? const Color(0xFFFFF7F0) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDefault ? const Color(0xFFFF6600) : Colors.transparent,
                  width: 1.5),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDefault
                      ? const Color(0xFFFF6600).withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  p['type'] == 'GCash' || p['type'] == 'PayMaya'
                      ? Icons.account_balance_wallet_outlined
                      : p['type'] == 'Cash on Delivery'
                          ? Icons.money_outlined
                          : Icons.credit_card_outlined,
                  color: isDefault ? const Color(0xFFFF6600) : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['type']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(p['detail']!,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ]),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF6600),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Default',
                      style: TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var pm in _payments) {
                        pm['isDefault'] = 'false';
                      }
                      _payments[i]['isDefault'] = 'true';
                      widget.onUpdatePayment(_payments[i]['type']!);
                    });
                    _snack('Default payment updated');
                  },
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Set default',
                      style: TextStyle(color: Color(0xFFFF6600), fontSize: 12)),
                ),
            ]),
          );
        }),
        GestureDetector(
          onTap: _showAddPaymentDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('Add Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),

        const SizedBox(height: 24),
        _sectionLabel('Account'),
        const SizedBox(height: 10),
        _actionTile(Icons.lock_outline, 'Change Password',
            Colors.grey.shade700, () => _snack('Feature coming soon')),
        _actionTile(Icons.help_outline, 'Help & Support',
            Colors.grey.shade700, () => _snack('Opening support...')),
        _actionTile(Icons.privacy_tip_outlined, 'Privacy Policy',
            Colors.grey.shade700, () => _snack('Opening privacy policy...')),
        _actionTile(Icons.delete_outline, 'Delete Account', Colors.red, () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              content: const Text('This action is permanent and cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    _snack('Account deletion requested', bg: Colors.red);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),
        Center(child: Text('FoodHub v1.0.0',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _switchTile({
    required IconData icon, required Color iconColor,
    required String title, required String subtitle,
    required bool value, required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ]),
        ),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(0xFFFF6600)),
      ]),
    );
  }

  Widget _actionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title,
              style: TextStyle(fontWeight: FontWeight.w600, color: color))),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1D26)));

  void _showAddPaymentDialog() {
    String selected = 'GCash';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['GCash', 'PayMaya', 'Visa', 'Mastercard', 'Cash on Delivery']
                .map((opt) => RadioListTile<String>(
                      title: Text(opt),
                      value: opt,
                      groupValue: selected,
                      activeColor: const Color(0xFFFF6600),
                      onChanged: (v) => setD(() => selected = v!),
                      contentPadding: EdgeInsets.zero,
                    ))
                .toList()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6600)),
              onPressed: () {
                setState(() => _payments.add({
                  'type': selected, 'detail': 'newly added', 'isDefault': 'false',
                }));
                Navigator.pop(context);
                _snack('$selected added');
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}