import 'package:flutter/material.dart';
import 'update_coffee.dart';

class ViewCoffeeScreen extends StatelessWidget {
  const ViewCoffeeScreen({super.key});

  final List<Map<String, String>> dummyCoffees = const [
    {"name": "Cappuccino", "price": "120"},
    {"name": "Latte", "price": "150"},
    {"name": "Espresso", "price": "100"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("View / Update Coffee")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyCoffees.length,
        itemBuilder: (context, index) {
          final coffee = dummyCoffees[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(coffee["name"]!),
              subtitle: Text("₹${coffee["price"]}"),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UpdateCoffeeScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
