import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../providers/cart_provider.dart';
import '../widgets/coffee_data.dart';

class CustomerAccountScreen extends ConsumerStatefulWidget {
  const CustomerAccountScreen({super.key});

  @override
  ConsumerState<CustomerAccountScreen> createState() =>
      _CustomerAccountScreenState();
}

class _CustomerAccountScreenState extends ConsumerState<CustomerAccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isProfileLoading = false);
      }
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!mounted) return;
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _isProfileLoading = false;
        });
      } else {
        setState(() => _isProfileLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _reorder(Map<String, dynamic> orderData) async {
    final items = (orderData['items'] as List?) ?? [];
    if (items.isEmpty) return;
    final cart = ref.read(cartProvider.notifier);
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final coffee = buildCustomCoffee(
        itemId: (raw['itemId'] ?? raw['name'] ?? 'item').toString(),
        name: (raw['name'] ?? 'Item').toString(),
        price: (raw['price'] ?? 0).toString(),
        image: 'assets/Menu_Items/Latte.png',
      );
      final qty = raw['qty'] is num ? (raw['qty'] as num).toInt() : 1;
      final notes = (raw['notes'] ?? '').toString();
      for (var i = 0; i < qty; i++) {
        cart.addItem(coffee, notes: notes);
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Order added to cart for quick reorder.')),
      );
  }

  Future<void> _requestCancellation(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Cancellation'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final paymentStatus = (orderData['paymentStatus'] ?? '').toString();
    await _firestore.collection('orders').doc(orderId).update({
      'cancellationRequest': {
        'status': 'pending',
        'reason': controller.text.trim(),
        'requestedAt': FieldValue.serverTimestamp(),
      },
      if (paymentStatus.toLowerCase() == 'paid') 'refundStatus': 'requested',
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': 'cancellation_requested',
          'time': DateTime.now().toIso8601String(),
        },
      ]),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cancellation request sent to shop.')),
    );
  }

  Future<void> _showRatingDialog(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    var selectedRating = (orderData['rating'] is num)
        ? (orderData['rating'] as num).toInt()
        : 5;
    final reviewController = TextEditingController(
      text: (orderData['review'] ?? '').toString(),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: const Text('Rate your order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final filled = index < selectedRating;
                    return IconButton(
                      onPressed: () {
                        setLocalState(() => selectedRating = index + 1);
                      },
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.caramel,
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: reviewController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write a quick review',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;
    final review = reviewController.text.trim();
    final shopId = (orderData['shopId'] ?? '').toString();
    final user = _auth.currentUser;

    await _firestore.collection('orders').doc(orderId).update({
      'rating': selectedRating,
      'review': review,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    if (shopId.isNotEmpty && user != null) {
      await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('reviews')
          .doc(orderId)
          .set({
            'orderId': orderId,
            'customerId': user.uid,
            'customerName': (_userData?['name'] ?? 'Customer').toString(),
            'rating': selectedRating,
            'review': review,
            'createdAt': FieldValue.serverTimestamp(),
          });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks! Your review was submitted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 360;
    final horizontalPadding = compact ? 12.0 : 16.0;
    final sectionGap = compact ? 10.0 : 14.0;

    if (user == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Session expired',
          subtitle: 'Please sign in again to view your account and orders.',
          actionLabel: 'Go to Login',
          onAction: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _isProfileLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      sectionGap,
                      horizontalPadding,
                      0,
                    ),
                    child: _buildProfileCard(
                      textTheme: textTheme,
                      compact: compact,
                      sectionGap: sectionGap,
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      labelStyle: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      labelColor: AppColors.espresso,
                      unselectedLabelColor: AppColors.ink.withOpacityValue(0.6),
                      indicator: BoxDecoration(
                        color: AppColors.oat,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tabs: const [
                        Tab(text: 'Active Orders'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildOrdersList(
                          query: _firestore
                              .collection('orders')
                              .where('customerId', isEqualTo: user.uid)
                              .where(
                                'status',
                                whereIn: [
                                  'new',
                                  'preparing',
                                  'ready',
                                  'picked',
                                ],
                              )
                              .orderBy('createdAt', descending: true),
                          emptyIcon: Icons.local_cafe_outlined,
                          emptyTitle: 'No active orders',
                          emptySubtitle:
                              'Your active orders will appear here once placed.',
                          horizontalPadding: horizontalPadding,
                          compact: compact,
                        ),
                        _buildOrdersList(
                          query: _firestore
                              .collection('orders')
                              .where('customerId', isEqualTo: user.uid)
                              .where(
                                'status',
                                whereIn: ['delivered', 'cancelled', 'rejected'],
                              )
                              .orderBy('createdAt', descending: true),
                          emptyIcon: Icons.history_rounded,
                          emptyTitle: 'No order history yet',
                          emptySubtitle:
                              'Delivered orders will show up here for quick review.',
                          horizontalPadding: horizontalPadding,
                          compact: compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildProfileCard({
    required TextTheme textTheme,
    required bool compact,
    required double sectionGap,
  }) {
    final name = (_userData?['name'] ?? 'Customer').toString();
    final email = (_userData?['email'] ?? '').toString();
    final phone = (_userData?['phone'] ?? 'No phone added').toString();
    final wallet = (_userData?['walletBalance'] is num)
        ? (_userData?['walletBalance'] as num).toDouble()
        : 0.0;
    final points = (_userData?['loyaltyPoints'] is num)
        ? (_userData?['loyaltyPoints'] as num).toInt()
        : 0;
    final wideActions = MediaQuery.sizeOf(context).width >= 390;
    final avatarRadius = compact ? 32.0 : 38.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.person_outline_rounded,
              title: 'Profile',
              subtitle: 'Your account and quick actions',
            ),
            SizedBox(height: sectionGap),
            Row(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: AppColors.espresso.withOpacityValue(0.1),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.espresso,
                    size: compact ? 30 : 36,
                  ),
                ),
                SizedBox(width: compact ? 12 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink.withOpacityValue(0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.ink.withOpacityValue(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sectionGap),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _statusBadge(
                  label: 'Wallet ${'\u{20B9}'}${wallet.toStringAsFixed(2)}',
                  color: AppColors.matcha,
                ),
                _statusBadge(label: 'Points $points', color: AppColors.caramel),
              ],
            ),
            SizedBox(height: sectionGap),
            if (wideActions)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/menu'),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Browse Menu'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/complaint-user'),
                      icon: const Icon(Icons.support_agent_outlined),
                      label: const Text('Contact Admin'),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/menu'),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Browse Menu'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/complaint-user'),
                      icon: const Icon(Icons.support_agent_outlined),
                      label: const Text('Contact Admin'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList({
    required Query<Map<String, dynamic>> query,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required double horizontalPadding,
    required bool compact,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Unable to load orders',
            subtitle: snapshot.error.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];
        if (orders.isEmpty) {
          return _EmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 4 : 6,
            horizontalPadding,
            compact ? 12 : 16,
          ),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = orders[index];
            return _buildOrderCard(doc.id, doc.data(), compact: compact);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
    String orderId,
    Map<String, dynamic> orderData, {
    required bool compact,
  }) {
    final statusKey = (orderData['status'] ?? 'new').toString();
    final statusMeta = _statusMeta(statusKey);
    final createdAt = _formatCreatedAt(orderData['createdAt']);
    final shopName = (orderData['shopName'] ?? 'Unknown Shop').toString();
    final paymentMethod = (orderData['paymentMethod'] ?? 'Unknown').toString();
    final paymentStatus =
        (orderData['paymentStatus'] ??
                (paymentMethod == 'Cash on Delivery' ? 'pending' : 'unknown'))
            .toString();
    final refundStatus = (orderData['refundStatus'] ?? '').toString();
    final cancellationRequest =
        orderData['cancellationRequest'] as Map<String, dynamic>?;
    final cancellationStatus = (cancellationRequest?['status'] ?? '')
        .toString()
        .toLowerCase();
    final rating = orderData['rating'] is num
        ? (orderData['rating'] as num).toInt()
        : null;
    final review = (orderData['review'] ?? '').toString();

    final rawItems = (orderData['items'] as List?) ?? [];
    final itemsSummary = rawItems.isEmpty
        ? 'No items'
        : rawItems
              .map((item) {
                if (item is! Map) return '';
                final name = (item['name'] ?? 'Item').toString();
                final qty = (item['qty'] ?? 1).toString();
                return '$name x$qty';
              })
              .where((line) => line.isNotEmpty)
              .join(', ');

    final total = (orderData['totalAmount'] ?? orderData['total'] ?? 0);
    final totalAsNum = total is num ? total.toDouble() : 0.0;
    final discount = (orderData['discountAmount'] is num)
        ? (orderData['discountAmount'] as num).toDouble()
        : 0.0;
    final tip = (orderData['tipAmount'] is num)
        ? (orderData['tipAmount'] as num).toDouble()
        : 0.0;
    final walletUsed = (orderData['walletUsed'] is num)
        ? (orderData['walletUsed'] as num).toDouble()
        : 0.0;
    final couponCode = (orderData['couponCode'] ?? '').toString();
    final invoice = orderData['invoice'] as Map<String, dynamic>?;
    final invoiceId = (invoice?['invoiceId'] ?? '').toString();
    final canRequestCancel =
        (statusKey == 'new' || statusKey == 'preparing') &&
        cancellationStatus.isEmpty;
    final orderLabel = orderId.length > 8
        ? orderId.substring(orderId.length - 8)
        : orderId;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #$orderLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _statusBadge(label: statusMeta.label, color: statusMeta.color),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.storefront_outlined, 'Shop', shopName),
            _infoRow(Icons.schedule_outlined, 'Time', createdAt),
            _infoRow(Icons.receipt_long_outlined, 'Items', itemsSummary),
            if (couponCode.isNotEmpty)
              _infoRow(Icons.sell_outlined, 'Coupon', couponCode),
            if (invoiceId.isNotEmpty)
              _infoRow(Icons.receipt_outlined, 'Invoice', invoiceId),
            if (discount > 0)
              _infoRow(
                Icons.discount_outlined,
                'Discount',
                '-${'\u{20B9}'}${discount.toStringAsFixed(2)}',
              ),
            if (walletUsed > 0)
              _infoRow(
                Icons.account_balance_wallet_outlined,
                'Wallet Used',
                '-${'\u{20B9}'}${walletUsed.toStringAsFixed(2)}',
              ),
            if (tip > 0)
              _infoRow(
                Icons.volunteer_activism_outlined,
                'Tip',
                '${'\u{20B9}'}${tip.toStringAsFixed(2)}',
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _statusBadge(
                    label: paymentStatus.toUpperCase(),
                    color: paymentStatus.toLowerCase() == 'paid'
                        ? AppColors.matcha
                        : paymentStatus.toLowerCase() == 'pending'
                        ? AppColors.caramel
                        : AppColors.espresso,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${'\u{20B9}'}${totalAsNum.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.espresso,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (refundStatus.isNotEmpty) ...[
              const SizedBox(height: 6),
              _statusBadge(
                label: 'REFUND ${refundStatus.toUpperCase()}',
                color: refundStatus.toLowerCase() == 'processed'
                    ? AppColors.matcha
                    : AppColors.caramel,
              ),
            ],
            if (cancellationStatus.isNotEmpty) ...[
              const SizedBox(height: 6),
              _statusBadge(
                label: 'CANCEL ${cancellationStatus.toUpperCase()}',
                color: cancellationStatus == 'approved'
                    ? AppColors.matcha
                    : cancellationStatus == 'rejected'
                    ? Colors.redAccent
                    : AppColors.caramel,
              ),
            ],
            if (rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 18,
                      color: AppColors.caramel,
                    ),
                  ),
                  if (review.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        review,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/track-order',
                    arguments: orderId,
                  ),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Track'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _reorder(orderData),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Reorder'),
                ),
                if (statusKey == 'delivered')
                  OutlinedButton.icon(
                    onPressed: () => _showRatingDialog(orderId, orderData),
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: Text(rating == null ? 'Rate' : 'Update Review'),
                  ),
                if (canRequestCancel)
                  TextButton.icon(
                    onPressed: () => _requestCancellation(orderId, orderData),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.ink.withOpacityValue(0.55)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink.withOpacityValue(0.65),
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.ink.withOpacityValue(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacityValue(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _OrderStatusMeta _statusMeta(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const _OrderStatusMeta('Order Placed', AppColors.caramel);
      case 'preparing':
        return const _OrderStatusMeta('Preparing', Color(0xFF3A7BD5));
      case 'ready':
        return const _OrderStatusMeta('Ready', AppColors.matcha);
      case 'picked':
        return const _OrderStatusMeta('Picked', Color(0xFF7A5CC7));
      case 'delivered':
        return const _OrderStatusMeta('Delivered', AppColors.matcha);
      case 'cancelled':
        return const _OrderStatusMeta('Cancelled', Colors.redAccent);
      case 'rejected':
        return const _OrderStatusMeta('Rejected', Colors.redAccent);
      default:
        return const _OrderStatusMeta('Unknown', AppColors.espresso);
    }
  }

  String _formatCreatedAt(dynamic createdAt) {
    DateTime? dateTime;
    if (createdAt is Timestamp) {
      dateTime = createdAt.toDate();
    } else if (createdAt is String) {
      dateTime = DateTime.tryParse(createdAt);
    }
    if (dateTime == null) return 'Not available';
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.oat,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.espresso),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink.withOpacityValue(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.oat,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.espresso, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.ink.withOpacityValue(0.65),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderStatusMeta {
  final String label;
  final Color color;

  const _OrderStatusMeta(this.label, this.color);
}
