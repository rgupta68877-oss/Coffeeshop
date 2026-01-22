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
    image: "assets/images/espresso.jpg",
  ),
  Coffee(
    itemId: "americano",
    name: "Americano",
    price: "90",
    image: "assets/images/americano.jpg",
  ),
  Coffee(
    itemId: "cappuccino",
    name: "Cappuccino",
    price: "150",
    image: "assets/images/cappuccino.jpg",
  ),
  Coffee(
    itemId: "latte",
    name: "Latte",
    price: "100",
    image: "assets/images/latte.jpg",
  ),
  Coffee(
    itemId: "flat_white",
    name: "Flat White",
    price: "130",
    image: "assets/images/flat_white.jpg",
  ),
  Coffee(
    itemId: "mocha",
    name: "Mocha",
    price: "120",
    image: "assets/images/mocha.jpg",
  ),
  Coffee(
    itemId: "macchiato",
    name: "Macchiato",
    price: "110",
    image: "assets/images/macchiato.jpg",
  ),
  Coffee(
    itemId: "cold_coffee",
    name: "Cold Coffee",
    price: "140",
    image: "assets/images/cold_coffee.jpg",
  ),
  Coffee(
    itemId: "iced_latte",
    name: "Iced Latte",
    price: "120",
    image: "assets/images/iced_latte.jpg",
  ),
  Coffee(
    itemId: "black_coffee",
    name: "Black Coffee",
    price: "70",
    image: "assets/images/black_coffee.jpg",
  ),

  // Snacks
  Coffee(
    itemId: "croissant",
    name: "Croissant",
    price: "60",
    image: "assets/images/croissant.jpg",
  ),
  Coffee(
    itemId: "chocolate_muffin",
    name: "Chocolate Muffin",
    price: "80",
    image: "assets/images/chocolate_muffin.jpg",
  ),
  Coffee(
    itemId: "veg_sandwich",
    name: "Veg Sandwich",
    price: "90",
    image: "assets/images/veg_sandwich.jpg",
  ),
];
