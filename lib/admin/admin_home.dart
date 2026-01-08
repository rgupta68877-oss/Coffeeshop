import 'package:flutter/material.dart';
import 'add_coffee.dart';
import 'view_coffee.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCoffeeScreen()),
                );
              },
              child: const Text("Add Coffee"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewCoffeeScreen()),
                );
              },
              child: const Text("View / Update Coffee"),
            ),
          ],
        ),
      ),
    );
  }
}
