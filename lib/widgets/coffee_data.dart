class Coffee {
  final String itemId;
  final String name;
  final String price;
  final String image;

  const Coffee({
    required this.itemId,
    required this.name,
    required this.price,
    required this.image,
  });
}

// Fixed menu items for all coffee shops
final List<Coffee> coffeeList = [
  // Coffee Drinks
  Coffee(
    itemId: "espresso",
    name: "Espresso",
    price: "80",
    image: "assets/images/Espresso.png",
  ),
  Coffee(
    itemId: "americano",
    name: "Americano",
    price: "90",
    image: "assets/images/Americano.png",
  ),
  Coffee(
    itemId: "cappuccino",
    name: "Cappuccino",
    price: "150",
    image: "assets/images/Cappuccino.png",
  ),
  Coffee(
    itemId: "latte",
    name: "Latte",
    price: "100",
    image: "assets/images/Latte.png",
  ),
  Coffee(
    itemId: "flat_white",
    name: "Flat White",
    price: "130",
    image: "assets/images/Flat White.png",
  ),
  Coffee(
    itemId: "mocha",
    name: "Mocha",
    price: "120",
    image: "assets/images/Mocha.png",
  ),
  Coffee(
    itemId: "macchiato",
    name: "Macchiato",
    price: "110",
    image: "assets/images/Macchiato.png",
  ),
  Coffee(
    itemId: "cold_coffee",
    name: "Cold Coffee",
    price: "140",
    image: "assets/images/Cold Coffee.png",
  ),
  Coffee(
    itemId: "iced_latte",
    name: "Iced Latte",
    price: "120",
    image: "assets/images/Iced Latte.png",
  ),
  Coffee(
    itemId: "black_coffee",
    name: "Black Coffee",
    price: "70",
    image: "assets/images/Espresso.png",
  ),

  // Snacks
  Coffee(
    itemId: "croissant",
    name: "Croissant",
    price: "60",
    image: "assets/images/Croissant.png",
  ),
  Coffee(
    itemId: "chocolate_muffin",
    name: "Chocolate Muffin",
    price: "80",
    image: "assets/images/Chocolate Muffin.png",
  ),
  Coffee(
    itemId: "veg_sandwich",
    name: "Veg Sandwich",
    price: "90",
    image: "assets/images/Veg Sandwich.png",
  ),
];
