import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../auth/login_screen.dart';

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
        backgroundColor: const Color(0xFF6F4E37),
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

    String itemsSummary = items.isNotEmpty
        ? items.map((item) => '${item['name']} x${item['qty']}').join(', ')
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
                Text(
                  'Order #$orderId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
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
            Text('Total: ₹${total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
