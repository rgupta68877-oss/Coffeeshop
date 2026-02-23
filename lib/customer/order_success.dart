import 'package:flutter/material.dart';
import '../customer/track_order_screen.dart';
import '../core/app_colors.dart';

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
    final textTheme = Theme.of(context).textTheme;

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.espresso, AppColors.cocoa, AppColors.caramel],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.matcha,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Order Successful!',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We are preparing your brew.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withOpacityValue(0.65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Redirecting to order tracking...',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.ink.withOpacityValue(0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
