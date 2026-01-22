import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? selectedPayment;
  bool _isPlacingOrder = false;

  Future<void> _placeOrder() async {
    if (selectedPayment == null) return;

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final shopId = userData['shopId'];

      // Get shop data
      final shopDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .get();

      if (!shopDoc.exists) return;

      final shopData = shopDoc.data()!;

      // Create order items
      final orderItems = cartProvider.items
          .map(
            (item) => OrderItem(
              itemId: item.coffee.itemId,
              name: item.coffee.name,
              price: double.parse(item.coffee.price),
              qty: item.qty,
            ),
          )
          .toList();

      // Create order
      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;
      final order = OrderModel(
        orderId: orderId,
        shopId: shopId,
        shopName: shopData['name'] ?? 'Unknown Shop',
        customerId: user.uid,
        customerName: userData['name'] ?? 'Unknown Customer',
        customerPhone: userData['phone'] ?? '',
        items: orderItems,
        totalAmount: cartProvider.totalAmount,
        status: 'new',
        statusHistory: [
          StatusHistory(status: 'new', time: DateTime.now().toString()),
        ],
        createdAt: DateTime.now().toString(),
      );

      // Save to Firestore
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        ...order.toJson(),
        'paymentMethod': selectedPayment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear cart
      cartProvider.clearCart();

      // Navigate to order success
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/order-success',
          arguments: orderId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.money),
              title: const Text("Cash on Delivery"),
              trailing: selectedPayment == "Cash on Delivery"
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  selectedPayment = "Cash on Delivery";
                });
              },
            ),

            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text("UPI / Card Payment"),
              trailing: selectedPayment == "UPI / Card Payment"
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  selectedPayment = "UPI / Card Payment";
                });
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedPayment == null || _isPlacingOrder
                    ? null
                    : _placeOrder,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                child: _isPlacingOrder
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Place Order", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
