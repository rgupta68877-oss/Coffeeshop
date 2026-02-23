import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class TrackOrderScreen extends StatefulWidget {
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../core/app_colors.dart';
import '../core/notifications/notification_service.dart';
import '../providers/app_database_provider.dart';

class TrackOrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: Colors.brown,
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  String? _lastStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final database = ref.read(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Order',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
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
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading order'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final order = OrderModel.fromJson(orderData);
          final paymentMethod = orderData['paymentMethod'] ?? 'Unknown';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${order.orderId}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Shop: ${order.shopName}'),
                        Text('Status: ${order.status}'),
                        Text('Payment: $paymentMethod'),
                        Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
                        Text('Ordered at: ${order.createdAt}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Order Items:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('Qty: ${item.qty}'),
                      trailing: Text('₹${item.price.toStringAsFixed(2)}'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Order Status:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStatusTimeline(order.status),
              ],
            ),
          );
          if (snapshot.hasData && snapshot.data!.exists) {
            final orderData = snapshot.data!.data() as Map<String, dynamic>;
            final normalized = _normalizeOrderPayload(orderData);
            database.upsertOrder(widget.orderId, normalized);
            return _buildOrderContent(normalized);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildCachedOrder(
              database,
              message: 'Loading live order updates...',
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return _buildCachedOrder(
              database,
              message:
                  'Unable to load live order. Showing last saved details if available.',
            );
          }

          return _buildCachedOrder(database, message: 'Order not found.');
        },
      ),
    );
  }

  Map<String, dynamic> _normalizeOrderPayload(
    Map<String, dynamic> orderData,
  ) {
    final paymentMethod = orderData['paymentMethod'] ?? 'Unknown';
    final paymentStatus = orderData['paymentStatus'] ??
        (paymentMethod == 'Cash on Delivery' ? 'pending' : 'unknown');
    final order = OrderModel.fromJson(orderData);
    return {
      ...order.toJson(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      if (orderData['deliveryAddress'] != null)
        'deliveryAddress': orderData['deliveryAddress'],
      if (orderData['paymentDetails'] != null)
        'paymentDetails': orderData['paymentDetails'],
    };
  }

  Widget _buildCachedOrder(AppDatabase database, {String? message}) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: database.getOrder(widget.orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cached = snapshot.data;
        if (cached == null) {
          return Center(child: Text(message ?? 'Order not found'));
        }

        return _buildOrderContent(
          cached,
          banner: message,
          isCached: true,
        );
      },
    );
  }

  Widget _buildOrderContent(
    Map<String, dynamic> orderData, {
    String? banner,
    bool isCached = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final order = OrderModel.fromJson(orderData);
    final paymentMethod = orderData['paymentMethod'] ?? 'Unknown';
    final paymentStatus = orderData['paymentStatus'] ??
        (paymentMethod == 'Cash on Delivery' ? 'pending' : 'unknown');

    if (!isCached && _lastStatus != order.status) {
      final previous = _lastStatus;
      _lastStatus = order.status;
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final message =
              'Order status updated to ${_getStatusText(order.status)}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          NotificationService.showLocalNotification(
            title: 'Order Update',
            body: message,
          );
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.oat,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.espresso),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      banner,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.espresso,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: ${order.orderId}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Shop: ${order.shopName}'),
                  Text('Status: ${_getStatusText(order.status)}'),
                  Text('Payment: $paymentMethod'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Payment Status: '),
                      _StatusPill(status: paymentStatus.toString()),
                    ],
                  ),
                  Text(
                    'Total: ${'\u{20B9}'}${order.totalAmount.toStringAsFixed(2)}',
                  ),
                  Text('Ordered at: ${order.createdAt}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Order Items',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (item) => Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(
                  item.notes.isEmpty
                      ? 'Qty: ${item.qty}'
                      : 'Qty: ${item.qty} • ${item.notes}',
                ),
                trailing: Text(
                  '${'\u{20B9}'}${item.price.toStringAsFixed(2)}',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Order Status',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusTimeline(order.status),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final statuses = ['new', 'preparing', 'ready', 'picked', 'delivered'];
    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      children: statuses.map((status) {
        final index = statuses.indexOf(status);
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return ListTile(
          leading: Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          title: Text(
            _getStatusText(status),
            style: TextStyle(
              color: isCompleted ? Colors.green : Colors.grey,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == statuses.length - 1;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.matcha : AppColors.oat,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.matcha
                            : AppColors.espresso.withOpacityValue(0.2),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 28,
                      color: isCompleted
                          ? AppColors.matcha
                          : AppColors.espresso.withOpacityValue(0.2),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getStatusText(status),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCompleted
                            ? AppColors.ink
                            : AppColors.ink.withOpacityValue(0.5),
                      ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'new':
        return 'Order Placed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'picked':
        return 'Picked Up';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  Widget _StatusPill({required String status}) {
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
