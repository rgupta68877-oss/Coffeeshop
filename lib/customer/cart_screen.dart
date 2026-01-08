import 'package:flutter/material.dart';
import '../widgets/coffee_data.dart';
import '../customer/order_success.dart';

class CartScreen extends StatelessWidget {
  final Coffee coffee;
  final String size;

  const CartScreen({
    super.key,
    required this.coffee,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    double price = double.parse(coffee.price);
    return Scaffold(
      appBar: AppBar(title: const Text("Cart")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              coffee.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Size: $size"),
            Text("Total: ₹${price.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderSuccess(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
              ),
              child: const Text("Place Order"),
            ),
          ],
        ),
      ),
    );
  }
}
