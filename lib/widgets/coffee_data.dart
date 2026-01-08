class Coffee {
  final String name;
  final String price;
  final String image;

  const Coffee({
    required this.name,
    required this.price,
    required this.image,
  });
}

// coffee_data.dart mein ye list rakhein
final List<Coffee> coffeeList = [
  Coffee(name: "Americano", price: "90", image: "assets/images/americano.jpg"),
  Coffee(name: "Cappuccino", price: "150", image: "assets/images/cappuccino.jpg"),
  Coffee(name: "Latte", price: "100", image: "assets/images/latte.jpg"),
  Coffee(name: "Mocha", price: "120", image: "assets/images/mocha.jpg"),
];
