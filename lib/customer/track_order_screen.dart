import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class TrackOrderScreen extends StatefulWidget {
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
        },
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
}
