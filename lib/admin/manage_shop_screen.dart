import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../widgets/coffee_card.dart';
import '../widgets/coffee_data.dart';
import '../core/app_colors.dart';

class ManageShopScreen extends StatefulWidget {
  const ManageShopScreen({super.key});

  @override
  State<ManageShopScreen> createState() => _ManageShopScreenState();
}

class _EditPriceDialog extends StatefulWidget {
  final String itemId;
  final double currentPrice;
  final String shopId;

  const _EditPriceDialog({
    required this.itemId,
    required this.currentPrice,
    required this.shopId,
  });

  @override
  State<_EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<_EditPriceDialog> {
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.currentPrice.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Price'),
      content: TextField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: const InputDecoration(labelText: 'Price'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newPrice = double.tryParse(_priceController.text);
            if (newPrice != null && newPrice > 0) {
              await FirebaseFirestore.instance
                  .collection('shops')
                  .doc(widget.shopId)
                  .collection('menu')
                  .doc(widget.itemId)
                  .update({'price': newPrice});
              if (!context.mounted) return;
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}

class _ManageShopScreenState extends State<ManageShopScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _shopId;
  String? _shopName;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return;

    final shopId = userDoc.data()?['shopId'] as String?;
    if (shopId == null || shopId.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _shopId = shopId;
    });

    final shopDoc = await _firestore.collection('shops').doc(shopId).get();
    if (!shopDoc.exists) return;

    if (!mounted) return;
    setState(() {
      _shopName = shopDoc.data()?['name'] as String? ?? 'Shop';
      _isOnline = shopDoc.data()?['status'] == 'online';
    });
  }

  Future<void> _toggleStatus() async {
    if (_shopId == null) return;
    final newStatus = _isOnline ? 'offline' : 'online';
    await _firestore.collection('shops').doc(_shopId).update({
      'status': newStatus,
      'lastActive': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() => _isOnline = !_isOnline);
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'statusHistory': FieldValue.arrayUnion([
        {'status': newStatus, 'time': DateTime.now().toString()},
      ]),
    });
  }

  Future<void> _logout() async {
    if (_shopId != null) {
      await _firestore.collection('shops').doc(_shopId).update({
        'status': 'offline',
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _initializeMenuItems() async {
    if (_shopId == null) return;

    try {
      final batch = _firestore.batch();
      for (final coffee in coffeeList) {
        final menuItemRef = _firestore
            .collection('shops')
            .doc(_shopId)
            .collection('menu')
            .doc();
        batch.set(menuItemRef, {
          'name': coffee.name,
          'price': int.parse(coffee.price),
          'imageUrl': coffee.image,
          'category': coffee.category,
          'description': coffee.description,
          'nutrition': {
            'kcal': coffee.nutrition.kcal,
            'protein': coffee.nutrition.protein,
            'carbs': coffee.nutrition.carbs,
            'fat': coffee.nutrition.fat,
            'caffeineMg': coffee.nutrition.caffeineMg,
          },
          'isSnack': coffee.isSnack,
          'badges': coffee.badges,
          'isDairyFree': coffee.isDairyFree,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu items initialized successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize menu items: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Shop'),
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.espresso, AppColors.cocoa, AppColors.caramel],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () => Navigator.pushNamed(context, '/owner-account'),
              tooltip: 'Account',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Menu'),
            ],
          ),
        ),
        body: _shopId == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.espresso, AppColors.cocoa],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shopName ?? 'Shop Name',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${_isOnline ? 'Online' : 'Offline'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isOnline,
                          onChanged: (_) => _toggleStatus(),
                          activeThumbColor: AppColors.matcha,
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('orders')
                        .where('shopId', isEqualTo: _shopId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final orders = snapshot.data!.docs;
                      double totalEarnings = 0;
                      int servedToday = 0;
                      int servedTotal = 0;
                      final now = DateTime.now();
                      for (final order in orders) {
                        final data = order.data() as Map<String, dynamic>;
                        if ((data['status'] ?? '') == 'delivered') {
                          servedTotal += 1;
                          totalEarnings +=
                              (data['totalAmount'] ?? data['total'] ?? 0.0)
                                  .toDouble();
                          final createdAt = _extractCreatedAt(data);
                          if (createdAt != null &&
                              createdAt.year == now.year &&
                              createdAt.month == now.month &&
                              createdAt.day == now.day) {
                            servedToday += 1;
                          }
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            _StatsCard(
                              label: 'Earnings',
                              value:
                                  '${'\u{20B9}'}${totalEarnings.toStringAsFixed(2)}',
                              icon: Icons.payments_outlined,
                            ),
                            const SizedBox(width: 12),
                            _StatsCard(
                              label: 'Served Today',
                              value: servedToday.toString(),
                              icon: Icons.today_outlined,
                            ),
                            const SizedBox(width: 12),
                            _StatsCard(
                              label: 'Served Total',
                              value: servedTotal.toString(),
                              icon: Icons.local_cafe_outlined,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('orders')
                              .where('shopId', isEqualTo: _shopId)
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading orders: ${snapshot.error}',
                                ),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final orders = snapshot.data!.docs;
                            if (orders.isEmpty) {
                              return const Center(child: Text('No orders yet'));
                            }
                            return ListView.builder(
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                final orderData =
                                    order.data() as Map<String, dynamic>;
                                return _buildOrderCard(order.id, orderData);
                              },
                            );
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('shops')
                              .doc(_shopId)
                              .collection('menu')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading menu: ${snapshot.error}',
                                ),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final menuItems = snapshot.data!.docs;
                            if (menuItems.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('No menu items found'),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Shop ID: $_shopId',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _initializeMenuItems,
                                      child: const Text(
                                        'Initialize Menu Items',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                              itemCount: menuItems.length,
                              itemBuilder: (context, index) {
                                final item = menuItems[index];
                                final itemData =
                                    item.data() as Map<String, dynamic>;
                                return _buildOwnerCoffeeCard(item.id, itemData);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> orderData) {
    final status = orderData['status'] ?? 'new';
    final time =
        (orderData['createdAt'] as Timestamp?)?.toDate().toString() ?? '';
    final items = orderData['items'] ?? [];
    final total = orderData['totalAmount'] ?? orderData['total'] ?? 0.0;
    final paymentMethod = orderData['paymentMethod'] ?? 'Unknown';
    final paymentStatus = orderData['paymentStatus'] ??
        (paymentMethod == 'Cash on Delivery' ? 'pending' : 'unknown');
    final customerName = orderData['customerName'] ?? 'Unknown';
    final customerPhone = orderData['customerPhone'] ?? 'Unknown';
    final deliveryAddress = orderData['deliveryAddress'];

    final itemsSummary = items.isNotEmpty
        ? items
            .map((item) {
              final notes = (item['notes'] ?? '').toString().trim().isEmpty
                  ? ''
                  : ' (${item['notes']})';
              return '${item['name']} x${item['qty']}$notes';
            })
            .join(', ')
        : 'No items';

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: $orderId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Customer: $customerName'),
            Text('Phone: $customerPhone'),
            Text('Time: $time'),
            Text('Items: $itemsSummary'),
            Text('Payment: $paymentMethod'),
            Text('Total: ${'\u{20B9}'}${total.toStringAsFixed(2)}'),
            if (deliveryAddress is Map<String, dynamic>)
              Text('Delivery: ${_formatAddress(deliveryAddress)}'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Payment Status: '),
                _statusPill(status: paymentStatus.toString()),
              ],
            ),
            const SizedBox(height: 8),
            _buildActionButton(orderId, status),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String orderId, String status) {
    switch (status) {
      case 'new':
        return Row(
          children: [
            ElevatedButton(
              onPressed: () => _updateOrderStatus(orderId, 'preparing'),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _updateOrderStatus(orderId, 'rejected'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      case 'preparing':
        return ElevatedButton(
          onPressed: () => _updateOrderStatus(orderId, 'ready'),
          child: const Text('Mark Ready'),
        );
      case 'ready':
        return ElevatedButton(
          onPressed: () => _updateOrderStatus(orderId, 'picked'),
          child: const Text('Mark Picked'),
        );
      case 'picked':
        return ElevatedButton(
          onPressed: () => _updateOrderStatus(orderId, 'delivered'),
          child: const Text('Mark Delivered'),
        );
      case 'delivered':
      default:
        return const Text('Delivered', style: TextStyle(color: Colors.green));
    }
  }

  void _showEditPriceDialog(String itemId, double currentPrice) {
    showDialog(
      context: context,
      builder: (context) => _EditPriceDialog(
        itemId: itemId,
        currentPrice: currentPrice,
        shopId: _shopId!,
      ),
    );
  }

  Future<void> _toggleAvailability(String itemId, bool isAvailable) async {
    await _firestore
        .collection('shops')
        .doc(_shopId)
        .collection('menu')
        .doc(itemId)
        .update({'isAvailable': isAvailable});
  }

  Widget _buildOwnerCoffeeCard(String itemId, Map<String, dynamic> itemData) {
    final name = itemData['name'] ?? 'Unknown Item';
    final price = itemData['price'] ?? 0.0;
    final imageUrl = itemData['imageUrl'] ?? '';
    final isAvailable = itemData['isAvailable'] ?? true;

    return CoffeeCard(
      name: name,
      price: price.toStringAsFixed(2),
      imagePath: imageUrl,
      isAvailable: isAvailable,
      showOwnerControls: true,
      onEditPrice: () => _showEditPriceDialog(itemId, price.toDouble()),
      onToggleAvailability: () => _toggleAvailability(itemId, !isAvailable),
    );
  }

  DateTime? _extractCreatedAt(Map<String, dynamic> data) {
    final value = data['createdAt'];
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _formatAddress(Map<String, dynamic> address) {
    final line1 = address['line1'] ?? '';
    final line2 = address['line2'] ?? '';
    final city = address['city'] ?? '';
    final pincode = address['pincode'] ?? '';
    final parts = [line1, line2, city, pincode]
        .where((part) => part.toString().trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  Widget _statusPill({required String status}) {
    final normalized = status.toLowerCase();
    final color = normalized == 'paid'
        ? AppColors.matcha
        : normalized == 'pending'
            ? AppColors.caramel
            : AppColors.espresso;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacityValue(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatsCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacityValue(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.espresso),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink.withOpacityValue(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
