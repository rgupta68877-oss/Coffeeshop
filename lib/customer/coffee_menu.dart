import 'package:flutter/material.dart';
import '../widgets/coffee_data.dart';
import '../widgets/coffee_card.dart';
import 'coffee_detail.dart';

class CoffeeMenu extends StatelessWidget {
  const CoffeeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Menu'),
        backgroundColor: Colors.brown,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Ek line mein 2 cards
          childAspectRatio: 0.8,
        ),
        itemCount: coffeeList.length,
        itemBuilder: (context, index) {
          final coffee = coffeeList[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoffeeDetail(
                    name: coffee.name,
                    price: coffee.price,
                    imagePath: coffee.image,
                  ),
                ),
              );
            },
            child: CoffeeCard(
              name: coffee.name,
              price: coffee.price,
              imagePath: coffee.image,
            ),
          );
        },
      ),
    );
  }
}
