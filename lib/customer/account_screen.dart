import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_colors.dart';

class CustomerAccountScreen extends StatefulWidget {
  const CustomerAccountScreen({super.key});

  @override
  State<CustomerAccountScreen> createState() => _CustomerAccountScreenState();
}

class _CustomerAccountScreenState extends State<CustomerAccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
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
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // User Info Section
                Container(
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFF2C1A0F),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFFC47A45),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userData!['name'] ?? 'Customer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userData!['email'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userData!['phone'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/menu');
                        },
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Browse Coffee Menu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC47A45),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/complaint-user');
                        },
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Contact Admin'),
                      ),
                    ],
                  ),
                ),

                // Orders Section
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Active Orders'),
                            Tab(text: 'Order History'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Active Orders Tab
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('orders')
                                    .where(
                                      'customerId',
                                      isEqualTo: _auth.currentUser!.uid,
                                    )
                                    .where(
                                      'status',
                                      whereIn: [
                                        'new',
                                        'preparing',
                                        'ready',
                                        'picked',
                                      ],
                                    )
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error: ${snapshot.error}'),
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
                                    return const Center(
                                      child: Text('No active orders'),
                                    );
                                  }
                                  return ListView.builder(
                                    itemCount: orders.length,
                                    itemBuilder: (context, index) {
                                      final order = orders[index];
                                      final orderData =
                                          order.data() as Map<String, dynamic>;
                                      return _buildOrderCard(
                                        order.id,
                                        orderData,
                                      );
                                    },
                                  );
                                },
                              ),

                              // Order History Tab
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('orders')
                                    .where(
                                      'customerId',
                                      isEqualTo: _auth.currentUser!.uid,
                                    )
                                    .where('status', isEqualTo: 'delivered')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error: ${snapshot.error}'),
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
                                    return const Center(
                                      child: Text('No order history'),
                                    );
                                  }
                                  return ListView.builder(
                                    itemCount: orders.length,
                                    itemBuilder: (context, index) {
                                      final order = orders[index];
                                      final orderData =
                                          order.data() as Map<String, dynamic>;
                                      return _buildOrderCard(
                                        order.id,
                                        orderData,
                                      );
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
                ),
              ],
            ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> orderData) {
    final status = orderData['status'] ?? 'new';
    final time =
        (orderData['createdAt'] as Timestamp?)?.toDate().toString() ?? '';
    final items = orderData['items'] ?? [];
    final total = orderData['totalAmount'] ?? 0.0;
    final shopName = orderData['shopName'] ?? 'Unknown Shop';
    final paymentMethod = orderData['paymentMethod'] ?? 'Unknown';
    final paymentStatus =
        orderData['paymentStatus'] ??
        (paymentMethod == 'Cash on Delivery' ? 'pending' : 'unknown');

    String itemsSummary = items.isNotEmpty
        ? items
              .map((item) {
                final notes = (item['notes'] ?? '').toString().trim().isEmpty
                    ? ''
                    : ' (${item['notes']})';
                return '${item['name']} x${item['qty']}$notes';
              })
              .join(', ')
        : 'No items';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'new':
        statusColor = Colors.orange;
        statusText = 'Order Placed';
        break;
      case 'preparing':
        statusColor = Colors.blue;
        statusText = 'Preparing';
        break;
      case 'ready':
        statusColor = Colors.green;
        statusText = 'Ready for Pickup';
        break;
      case 'picked':
        statusColor = Colors.purple;
        statusText = 'Picked Up';
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusText = 'Delivered';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #$orderId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Shop: $shopName'),
            Text('Time: $time'),
            Text('Items: $itemsSummary'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Payment Status: '),
                _StatusPill(status: paymentStatus.toString()),
              ],
            ),
            Text('Total: ${'\u{20B9}'}${total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _StatusPill({required String status}) {
    final normalized = status.toLowerCase();
    final color = normalized == 'paid'
        ? Colors.green
        : normalized == 'pending'
        ? Colors.orange
        : Colors.grey;
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
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
