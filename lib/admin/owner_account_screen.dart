import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';

class OwnerAccountScreen extends StatefulWidget {
  const OwnerAccountScreen({super.key});

  @override
  State<OwnerAccountScreen> createState() => _OwnerAccountScreenState();
}

class _OwnerAccountScreenState extends State<OwnerAccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _shopData;
  bool _isLoading = true;

  String get _shopId => (_userData?['shopId'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    Map<String, dynamic>? shopData;
    final shopId = (userData?['shopId'] ?? '').toString();
    if (shopId.isNotEmpty) {
      final shopDoc = await _firestore.collection('shops').doc(shopId).get();
      shopData = shopDoc.data();
    }
    if (!mounted) return;
    setState(() {
      _userData = userData;
      _shopData = shopData;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Owner Account'),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
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
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOwnerData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 12),
                  _buildShopCard(),
                  const SizedBox(height: 12),
                  _buildBusinessSummary(),
                  const SizedBox(height: 12),
                  _buildActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    final user = _auth.currentUser;
    final name = (_userData?['name'] ?? 'Owner').toString();
    final email = user?.email ?? (_userData?['email'] ?? '').toString();
    final phone = (_userData?['phone'] ?? 'No phone added').toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.espresso.withOpacityValue(0.12),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.espresso,
                size: 34,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withOpacityValue(0.7),
                    ),
                  ),
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ink.withOpacityValue(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard() {
    final shopName = (_shopData?['name'] ?? 'Shop not linked').toString();
    final address = (_shopData?['address'] ?? 'Add shop address').toString();
    final status = (_shopData?['status'] ?? 'offline').toString();
    final isOnline = status.toLowerCase() == 'online';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _labelRow('Name', shopName),
            _labelRow('Shop ID', _shopId.isEmpty ? 'Not linked' : _shopId),
            _labelRow('Address', address),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isOnline ? AppColors.matcha : AppColors.caramel)
                    .withOpacityValue(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  color: isOnline ? AppColors.matcha : AppColors.caramel,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSummary() {
    if (_shopId.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Link your shop to view business analytics.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('orders')
          .where('shopId', isEqualTo: _shopId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final orders = snapshot.data!.docs;
        var active = 0;
        var servedToday = 0;
        var lifetimeRevenue = 0.0;
        final now = DateTime.now();
        for (final doc in orders) {
          final data = doc.data();
          final status = (data['status'] ?? '').toString().toLowerCase();
          final total = data['totalAmount'] ?? data['total'] ?? 0;
          final totalAsNum = total is num ? total.toDouble() : 0.0;
          if (status == 'new' ||
              status == 'preparing' ||
              status == 'ready' ||
              status == 'picked') {
            active += 1;
          }
          if (status == 'delivered') {
            lifetimeRevenue += totalAsNum;
            final createdAt = data['createdAt'];
            DateTime? createdDate;
            if (createdAt is Timestamp) {
              createdDate = createdAt.toDate();
            } else if (createdAt is String) {
              createdDate = DateTime.tryParse(createdAt);
            }
            if (createdDate != null &&
                createdDate.year == now.year &&
                createdDate.month == now.month &&
                createdDate.day == now.day) {
              servedToday += 1;
            }
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _metricTile(
                      label: 'Active',
                      value: active.toString(),
                      icon: Icons.pending_actions_rounded,
                    ),
                    const SizedBox(width: 10),
                    _metricTile(
                      label: 'Served Today',
                      value: servedToday.toString(),
                      icon: Icons.today_outlined,
                    ),
                    const SizedBox(width: 10),
                    _metricTile(
                      label: 'Revenue',
                      value:
                          '${'\u{20B9}'}${lifetimeRevenue.toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/manage-shop'),
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: const Text('Go To Manage Shop'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/complaint-owner'),
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('Contact Admin'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.oat,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.espresso),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink.withOpacityValue(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.ink.withOpacityValue(0.65),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.ink.withOpacityValue(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
