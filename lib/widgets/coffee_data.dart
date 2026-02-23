class Nutrition {
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final int caffeineMg;

  const Nutrition({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.caffeineMg,
  });
}

class Coffee {
  final String itemId;
  final String name;
  final String price;
  final String image;
  final String category;
  final String description;
  final Nutrition nutrition;
  final List<String> badges;
  final bool isDairyFree;
  final bool isSnack;

  const Coffee({
    required this.itemId,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.description,
    required this.nutrition,
    this.badges = const [],
    this.isDairyFree = false,
    this.isSnack = false,
  });
}

class MenuCategory {
  static const String espresso = 'Espresso & Coffee';
  static const String cold = 'Cold Coffee';
  static const String tea = 'Tea & Matcha';
  static const String boba = 'Boba';
  static const String bakery = 'Bakery & Desserts';
  static const String other = 'Other';
}

const List<String> menuCategories = [
  MenuCategory.espresso,
  MenuCategory.cold,
  MenuCategory.tea,
  MenuCategory.boba,
  MenuCategory.bakery,
];

const Nutrition _coffeeNutrition = Nutrition(
  kcal: 140,
  protein: 6,
  carbs: 16,
  fat: 6,
  caffeineMg: 120,
);
const Nutrition _coldCoffeeNutrition = Nutrition(
  kcal: 180,
  protein: 5,
  carbs: 24,
  fat: 7,
  caffeineMg: 140,
);
const Nutrition _teaNutrition = Nutrition(
  kcal: 110,
  protein: 3,
  carbs: 20,
  fat: 2,
  caffeineMg: 45,
);
const Nutrition _bobaNutrition = Nutrition(
  kcal: 260,
  protein: 4,
  carbs: 52,
  fat: 5,
  caffeineMg: 60,
);
const Nutrition _bakeryNutrition = Nutrition(
  kcal: 320,
  protein: 6,
  carbs: 44,
  fat: 14,
  caffeineMg: 0,
);
const Nutrition _otherNutrition = Nutrition(
  kcal: 150,
  protein: 4,
  carbs: 20,
  fat: 5,
  caffeineMg: 20,
);

Nutrition _nutritionForCategory(String category) {
  switch (category) {
    case MenuCategory.espresso:
      return _coffeeNutrition;
    case MenuCategory.cold:
      return _coldCoffeeNutrition;
    case MenuCategory.tea:
      return _teaNutrition;
    case MenuCategory.boba:
      return _bobaNutrition;
    case MenuCategory.bakery:
      return _bakeryNutrition;
    default:
      return _otherNutrition;
  }
}

String _descriptionForCategory(String category) {
  switch (category) {
    case MenuCategory.espresso:
      return 'Crafted with premium beans for a bold, balanced flavor.';
    case MenuCategory.cold:
      return 'Chilled and refreshing with a smooth, clean finish.';
    case MenuCategory.tea:
      return 'A soothing blend with gentle sweetness and aroma.';
    case MenuCategory.boba:
      return 'Creamy tea paired with chewy boba pearls.';
    case MenuCategory.bakery:
      return 'Baked fresh for a soft, rich, and satisfying bite.';
    default:
      return 'House favorite made with love.';
  }
}

Nutrition defaultNutritionForCategory(String category) =>
    _nutritionForCategory(category);

String defaultDescriptionForCategory(String category) =>
    _descriptionForCategory(category);

Coffee _buildCoffee({
  required String itemId,
  required String name,
  required String price,
  required String image,
  required String category,
  bool isSnack = false,
  bool isDairyFree = false,
  List<String> badges = const [],
  String? description,
  Nutrition? nutrition,
}) {
  return Coffee(
    itemId: itemId,
    name: name,
    price: price,
    image: image,
    category: category,
    description: description ?? _descriptionForCategory(category),
    nutrition: nutrition ?? _nutritionForCategory(category),
    badges: badges,
    isDairyFree: isDairyFree,
    isSnack: isSnack,
  );
}

final List<Coffee> coffeeList = [
  _buildCoffee(
    itemId: 'espresso',
    name: 'Espresso',
    price: '90',
    image: 'assets/Menu_Items/Espresso.png',
    category: MenuCategory.espresso,
    isDairyFree: true,
    badges: ['Top Seller'],
  ),
  _buildCoffee(
    itemId: 'ristretto',
    name: 'Ristretto',
    price: '95',
    image: 'assets/Menu_Items/Ristretto.png',
    category: MenuCategory.espresso,
    isDairyFree: true,
  ),
  _buildCoffee(
    itemId: 'americano',
    name: 'Americano',
    price: '110',
    image: 'assets/Menu_Items/Americano.png',
    category: MenuCategory.espresso,
    isDairyFree: true,
  ),
  _buildCoffee(
    itemId: 'cappuccino',
    name: 'Cappuccino',
    price: '150',
    image: 'assets/Menu_Items/Cappuccino.png',
    category: MenuCategory.espresso,
    badges: ['Popular'],
  ),
  _buildCoffee(
    itemId: 'latte',
    name: 'Latte',
    price: '160',
    image: 'assets/Menu_Items/Latte.png',
    category: MenuCategory.espresso,
    badges: ['Best Seller'],
  ),
  _buildCoffee(
    itemId: 'mocha',
    name: 'Mocha',
    price: '170',
    image: 'assets/Menu_Items/Mocha.png',
    category: MenuCategory.espresso,
    badges: ['New'],
  ),
  _buildCoffee(
    itemId: 'flat_white',
    name: 'Flat White',
    price: '160',
    image: 'assets/Menu_Items/Flat White.png',
    category: MenuCategory.espresso,
  ),
  _buildCoffee(
    itemId: 'cortado',
    name: 'Cortado',
    price: '140',
    image: 'assets/Menu_Items/Cortado.png',
    category: MenuCategory.espresso,
    badges: ['Low Sugar'],
  ),
  _buildCoffee(
    itemId: 'caramel_macchiato',
    name: 'Caramel Macchiato',
    price: '180',
    image: 'assets/Menu_Items/Caramel Macchiato.png',
    category: MenuCategory.espresso,
  ),
  _buildCoffee(
    itemId: 'vanilla_latte',
    name: 'Vanilla Latte',
    price: '175',
    image: 'assets/Menu_Items/Vanilla Latte.png',
    category: MenuCategory.espresso,
  ),
  _buildCoffee(
    itemId: 'hazelnut_cappuccino',
    name: 'Hazelnut Cappuccino',
    price: '170',
    image: 'assets/Menu_Items/Hazelnut Cappuccino.png',
    category: MenuCategory.espresso,
  ),
  _buildCoffee(
    itemId: 'irish_coffee',
    name: 'Irish Coffee',
    price: '190',
    image: 'assets/Menu_Items/Irish Coffee.png',
    category: MenuCategory.espresso,
    badges: ['Seasonal'],
  ),
  _buildCoffee(
    itemId: 'affogato',
    name: 'Affogato',
    price: '200',
    image: 'assets/Menu_Items/Affogato.png',
    category: MenuCategory.espresso,
  ),
  _buildCoffee(
    itemId: 'iced_coffee',
    name: 'Iced Coffee',
    price: '140',
    image: 'assets/Menu_Items/Iced Coffee.png',
    category: MenuCategory.cold,
    badges: ['Popular'],
  ),
  _buildCoffee(
    itemId: 'iced_americano',
    name: 'Iced Americano',
    price: '150',
    image: 'assets/Menu_Items/Iced Americano.png',
    category: MenuCategory.cold,
    isDairyFree: true,
  ),
  _buildCoffee(
    itemId: 'cold_brew',
    name: 'Cold Brew',
    price: '170',
    image: 'assets/Menu_Items/Cold Brew.png',
    category: MenuCategory.cold,
    isDairyFree: true,
    badges: ['Top Seller'],
  ),
  _buildCoffee(
    itemId: 'nitro_cold_brew',
    name: 'Nitro Cold Brew',
    price: '190',
    image: 'assets/Menu_Items/Nitro Cold Brew.png',
    category: MenuCategory.cold,
    isDairyFree: true,
  ),
  _buildCoffee(
    itemId: 'frappuccino',
    name: 'Frappuccino',
    price: '200',
    image: 'assets/Menu_Items/Frappuccino.png',
    category: MenuCategory.cold,
  ),
  _buildCoffee(
    itemId: 'matcha_latte',
    name: 'Matcha Latte',
    price: '180',
    image: 'assets/Menu_Items/Matcha Latte.png',
    category: MenuCategory.tea,
  ),
  _buildCoffee(
    itemId: 'iced_matcha_latte',
    name: 'Iced Matcha Latte',
    price: '190',
    image: 'assets/Menu_Items/Iced Matcha Latte.png',
    category: MenuCategory.tea,
  ),
  _buildCoffee(
    itemId: 'matcha_tea',
    name: 'Matcha Tea',
    price: '130',
    image: 'assets/Menu_Items/Matcha Tea.png',
    category: MenuCategory.tea,
    isDairyFree: true,
    badges: ['Low Sugar'],
  ),
  _buildCoffee(
    itemId: 'chai_latte',
    name: 'Chai Latte',
    price: '160',
    image: 'assets/Menu_Items/Chai Latte.png',
    category: MenuCategory.tea,
  ),
  _buildCoffee(
    itemId: 'green_tea',
    name: 'Green Tea',
    price: '120',
    image: 'assets/Menu_Items/Green Tea.png',
    category: MenuCategory.tea,
    isDairyFree: true,
  ),
  _buildCoffee(
    itemId: 'peach_iced_tea',
    name: 'Peach Iced Tea',
    price: '140',
    image: 'assets/Menu_Items/Peach Iced Tea.png',
    category: MenuCategory.tea,
    isDairyFree: true,
  ),
  _buildCoffee(
    itemId: 'hot_chocolate',
    name: 'Hot Chocolate',
    price: '160',
    image: 'assets/Menu_Items/Hot Chocolate.png',
    category: MenuCategory.tea,
  ),
  _buildCoffee(
    itemId: 'classic_milk_boba_tea',
    name: 'Classic Milk Boba Tea',
    price: '180',
    image: 'assets/Menu_Items/Classic Milk Boba Tea.png',
    category: MenuCategory.boba,
  ),
  _buildCoffee(
    itemId: 'brown_sugar_boba_tea',
    name: 'Brown Sugar Boba Tea',
    price: '200',
    image: 'assets/Menu_Items/Brown Sugar Boba Tea.png',
    category: MenuCategory.boba,
    badges: ['Popular'],
  ),
  _buildCoffee(
    itemId: 'mango_boba_tea',
    name: 'Mango Boba Tea',
    price: '190',
    image: 'assets/Menu_Items/Mango Boba Tea.png',
    category: MenuCategory.boba,
  ),
  _buildCoffee(
    itemId: 'taro_boba_tea',
    name: 'Taro Boba Tea',
    price: '190',
    image: 'assets/Menu_Items/Taro Boba Tea.png',
    category: MenuCategory.boba,
  ),
  _buildCoffee(
    itemId: 'strawberry_milk_boba',
    name: 'Strawberry Milk Boba',
    price: '190',
    image: 'assets/Menu_Items/Strawberry Milk Boba.png',
    category: MenuCategory.boba,
  ),
  _buildCoffee(
    itemId: 'thai_milk_tea_boba',
    name: 'Thai Milk Tea Boba',
    price: '200',
    image: 'assets/Menu_Items/Thai Milk Tea Boba.png',
    category: MenuCategory.boba,
  ),
  _buildCoffee(
    itemId: 'croissant',
    name: 'Croissant',
    price: '120',
    image: 'assets/Menu_Items/Croissant.png',
    category: MenuCategory.bakery,
    isSnack: true,
  ),
  _buildCoffee(
    itemId: 'cinnamon_roll',
    name: 'Cinnamon Roll',
    price: '160',
    image: 'assets/Menu_Items/Cinnamon Roll.png',
    category: MenuCategory.bakery,
    isSnack: true,
  ),
  _buildCoffee(
    itemId: 'blueberry_muffin',
    name: 'Blueberry Muffin',
    price: '140',
    image: 'assets/Menu_Items/Blueberry Muffin.png',
    category: MenuCategory.bakery,
    isSnack: true,
  ),
  _buildCoffee(
    itemId: 'donut',
    name: 'Donut',
    price: '100',
    image: 'assets/Menu_Items/Donut.png',
    category: MenuCategory.bakery,
    isSnack: true,
  ),
  _buildCoffee(
    itemId: 'cheesecake_slice',
    name: 'Cheesecake Slice',
    price: '220',
    image: 'assets/Menu_Items/Cheesecake Slice.png',
    category: MenuCategory.bakery,
    isSnack: true,
  ),
  _buildCoffee(
    itemId: 'chocolate_brownie',
    name: 'Chocolate Brownie',
    price: '180',
    image: 'assets/Menu_Items/Chocolate Brownie.png',
    category: MenuCategory.bakery,
    isSnack: true,
  ),
  _buildCoffee(
    itemId: 'red_velvet_cake_slice',
    name: 'Red Velvet Cake Slice',
    price: '230',
    image: 'assets/Menu_Items/Red Velvet Cake Slice.png',
    category: MenuCategory.bakery,
    isSnack: true,
  ),
];

Coffee? findCoffeeByName(String name) {
  final target = name.trim().toLowerCase();
  for (final coffee in coffeeList) {
    if (coffee.name.toLowerCase() == target) {
      return coffee;
    }
  }
  return null;
}

List<Coffee> snackOptions() =>
    coffeeList.where((coffee) => coffee.isSnack).toList();

Coffee buildCustomCoffee({
  required String itemId,
  required String name,
  required String price,
  required String image,
  String? category,
  String? description,
  Nutrition? nutrition,
  List<String>? badges,
  bool? isDairyFree,
  bool isSnack = false,
}) {
  final resolvedCategory = category ?? MenuCategory.other;
  return Coffee(
    itemId: itemId,
    name: name,
    price: price,
    image: image,
    category: resolvedCategory,
    description: description ?? defaultDescriptionForCategory(resolvedCategory),
    nutrition: nutrition ?? defaultNutritionForCategory(resolvedCategory),
    badges: badges ?? const [],
    isDairyFree: isDairyFree ?? false,
    isSnack: isSnack,
  );
}
