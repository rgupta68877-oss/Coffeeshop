import 'package:flutter/material.dart';
import '../customer/track_order_screen.dart';

class OrderSuccess extends StatefulWidget {
  final String orderId;

  const OrderSuccess({super.key, required this.orderId});

  @override
  State<OrderSuccess> createState() => _OrderSuccessState();
}

class _OrderSuccessState extends State<OrderSuccess> {
  @override
  void initState() {
    super.initState();
    // Navigate to track order after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrackOrderScreen(orderId: widget.orderId),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text("Order Successful!", style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text(
              "Redirecting to order tracking...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
