import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/coffee_data.dart';
import '../widgets/coffee_card.dart';
import 'coffee_detail.dart';
import '../providers/cart_provider.dart';

class CoffeeMenu extends StatefulWidget {
  const CoffeeMenu({super.key});

  @override
  State<CoffeeMenu> createState() => _CoffeeMenuState();
}

class _CoffeeMenuState extends State<CoffeeMenu> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedShopId;
  String? _selectedShopName;
import '../core/app_colors.dart';

class CoffeeMenu extends ConsumerStatefulWidget {
  const CoffeeMenu({super.key});

  @override
  ConsumerState<CoffeeMenu> createState() => _CoffeeMenuState();
}

class _CoffeeMenuState extends ConsumerState<CoffeeMenu> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedShopId;
  String? _selectedShopName;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _filterUnder150 = false;
  bool _filterDairyFree = false;
  bool _filterCaffeineBoost = false;
  bool _filterSnacks = false;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _addToCart(Coffee coffee) {
    context.read<CartProvider>().addItem(coffee);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${coffee.name} added to cart!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDefaultMenu() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
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
                  shopId: '',
                  shopName: 'Default Menu',
                ),
              ),
            );
          },
          child: CoffeeCard(
            name: coffee.name,
            price: coffee.price,
            imagePath: coffee.image,
            onAddToCart: () => _addToCart(coffee),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Coffee Menu'),
        backgroundColor: Colors.brown,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                  tooltip: 'Cart',
                ),
                if (cart.totalQty > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.totalQty}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/customer-account');
            },
            tooltip: 'Account',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          // Shop Selection
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.brown[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Shop',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('shops')
                      .where('status', isEqualTo: 'online')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading shops');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final shops = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'id': doc.id,
                        'name': data['name'] ?? 'Unknown Shop',
                        'address': data['address'] ?? '',
                      };
                    }).toList();

                    return DropdownButtonFormField<String>(
                      value: _selectedShopId,
                      hint: const Text('Choose a shop'),
                      items: shops.map((shop) {
                        return DropdownMenuItem<String>(
                          value: shop['id'],
                          child: Text('${shop['name']} - ${shop['address']}'),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          _selectedShopId = value;
                          _selectedShopName = shops.firstWhere(
                            (shop) => shop['id'] == value,
                            orElse: () => {'name': 'Unknown'},
                          )['name'];
                        });

                        // Save selected shop to user document
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && value != null) {
                          await _firestore
                              .collection('users')
                              .doc(user.uid)
                              .update({
                                'shopId': value,
                                'shopName': _selectedShopName,
                              });
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: _selectedShopId == null
                ? _buildDefaultMenu()
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('shops')
                        .doc(_selectedShopId)
                        .collection('menu')
                        .where('isAvailable', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading menu'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final menuItems = snapshot.data!.docs;
                      if (menuItems.isEmpty) {
                        return const Center(
                          child: Text('No menu items available'),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          final item = menuItems[index];
                          final itemData = item.data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CoffeeDetail(
                                    name: itemData['name'] ?? 'Unknown',
                                    price: itemData['price']?.toString() ?? '0',
                                    imagePath: itemData['imageUrl'] ?? '',
                                    shopId: _selectedShopId!,
                                    shopName: _selectedShopName!,
                                  ),
                                ),
                              );
                            },
                            child: CoffeeCard(
                              name: itemData['name'] ?? 'Unknown',
                              price: itemData['price']?.toString() ?? '0',
                              imagePath: itemData['imageUrl'] ?? '',
                              onAddToCart: () => _addToCart(
                                Coffee(
                                  itemId: item.id,
                                  name: itemData['name'] ?? 'Unknown',
                                  price: itemData['price']?.toString() ?? '0',
                                  image: itemData['imageUrl'] ?? '',
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
    ref.read(cartProvider.notifier).addItem(coffee);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${coffee.name} added to cart!'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }

  Coffee _coffeeFromFirestore(DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';
    final price = data['price']?.toString() ?? '0';
    final imageUrl = data['imageUrl'] ?? '';
    final category = data['category'];
    final description = data['description'];
    final nutrition = data['nutrition'];
    final isSnack = data['isSnack'];
    final badges = data['badges'];
    final isDairyFree = data['isDairyFree'];
    final match = findCoffeeByName(name);
    Nutrition? parsedNutrition;
    if (nutrition is Map<String, dynamic>) {
      final kcal = nutrition['kcal'];
      final protein = nutrition['protein'];
      final carbs = nutrition['carbs'];
      final fat = nutrition['fat'];
      final caffeineMg = nutrition['caffeineMg'];
      if (kcal != null &&
          protein != null &&
          carbs != null &&
          fat != null &&
          caffeineMg != null) {
        parsedNutrition = Nutrition(
          kcal: (kcal as num).toInt(),
          protein: (protein as num).toDouble(),
          carbs: (carbs as num).toDouble(),
          fat: (fat as num).toDouble(),
          caffeineMg: (caffeineMg as num).toInt(),
        );
      }
    }
    return buildCustomCoffee(
      itemId: item.id,
      name: name,
      price: price,
      image: imageUrl.isNotEmpty
          ? imageUrl
          : (match?.image ?? 'assets/Menu_Items/Latte.png'),
      category: category ?? match?.category ?? MenuCategory.other,
      description: description ?? match?.description,
      nutrition: parsedNutrition ?? match?.nutrition,
      badges: badges is List ? badges.cast<String>() : match?.badges,
      isDairyFree: isDairyFree ?? match?.isDairyFree ?? false,
      isSnack: isSnack ?? match?.isSnack ?? false,
    );
  }

  List<String> _categoryOptions(List<Coffee> coffees) {
    final hasOther =
        coffees.any((coffee) => coffee.category == MenuCategory.other);
    return [
      'All',
      ...menuCategories,
      if (hasOther) MenuCategory.other,
    ];
  }

  List<Coffee> _filterByCategory(List<Coffee> coffees) {
    final categoryFiltered = _selectedCategory == 'All'
        ? coffees
        : coffees
            .where((coffee) => coffee.category == _selectedCategory)
            .toList();
    if (_searchQuery.trim().isEmpty) {
      return _applyFilters(categoryFiltered);
    }
    final query = _searchQuery.toLowerCase();
    final searched = categoryFiltered
        .where((coffee) => coffee.name.toLowerCase().contains(query))
        .toList();
    return _applyFilters(searched);
  }

  List<Coffee> _applyFilters(List<Coffee> coffees) {
    var filtered = coffees;
    if (_filterUnder150) {
      filtered = filtered
          .where((coffee) => double.tryParse(coffee.price) != null)
          .where((coffee) => double.parse(coffee.price) <= 150)
          .toList();
    }
    if (_filterDairyFree) {
      filtered = filtered.where((coffee) => coffee.isDairyFree).toList();
    }
    if (_filterCaffeineBoost) {
      filtered =
          filtered.where((coffee) => coffee.nutrition.caffeineMg >= 120).toList();
    }
    if (_filterSnacks) {
      filtered = filtered.where((coffee) => coffee.isSnack).toList();
    }
    return filtered;
  }

  Widget _buildMenuContent({
    required List<Coffee> coffees,
    required String shopId,
    required String shopName,
    bool isLoading = false,
  }) {
    final filtered = _filterByCategory(coffees);
    final categories = _categoryOptions(coffees);
    return CustomScrollView(
      key: PageStorageKey('menu_scroll_$shopId'),
      slivers: [
        SliverToBoxAdapter(
          child: _buildShopSelector(),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _MenuHeaderDelegate(
            minHeight: 176,
            maxHeight: 176,
            child: _buildMenuHeader(categories),
          ),
        ),
        if (isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filtered.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No items in this category')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final coffee = filtered[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoffeeDetail(
                            coffee: coffee,
                            shopId: shopId,
                            shopName: shopName,
                            snackOptions: snackOptions(),
                          ),
                        ),
                      );
                    },
                    child: CoffeeCard(
                      name: coffee.name,
                      price: coffee.price,
                      imagePath: coffee.image,
                      badgeText:
                          coffee.badges.isNotEmpty ? coffee.badges.first : null,
                      onAddToCart: () => _addToCart(coffee),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coffee Menu',
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Choose your shop and brew',
              style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.espresso, AppColors.cocoa, AppColors.caramel],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                tooltip: 'Cart',
              ),
              if (cart.totalQty > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.matcha,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.totalQty}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/customer-account');
            },
            tooltip: 'Account',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _selectedShopId == null
          ? _buildMenuContent(
              coffees: coffeeList,
              shopId: '',
              shopName: 'Default Menu',
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('shops')
                  .doc(_selectedShopId)
                  .collection('menu')
                  .where('isAvailable', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading menu'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildMenuContent(
                    coffees: const [],
                    shopId: _selectedShopId!,
                    shopName: _selectedShopName ?? 'Coffee Shop',
                    isLoading: true,
                  );
                }
                final menuItems = snapshot.data!.docs;
                if (menuItems.isEmpty) {
                  return _buildMenuContent(
                    coffees: const [],
                    shopId: _selectedShopId!,
                    shopName: _selectedShopName ?? 'Coffee Shop',
                  );
                }
                final coffees =
                    menuItems.map((item) => _coffeeFromFirestore(item)).toList();
                return _buildMenuContent(
                  coffees: coffees,
                  shopId: _selectedShopId!,
                  shopName: _selectedShopName ?? 'Coffee Shop',
                );
              },
            ),
    );
  }

  Widget _buildShopSelector() {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Shop',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('shops')
                    .where('status', isEqualTo: 'online')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error loading shops');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final shops = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'name': data['name'] ?? 'Unknown Shop',
                      'address': data['address'] ?? '',
                    };
                  }).toList();

                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedShopId,
                    hint: const Text('Choose a shop'),
                    items: shops.map((shop) {
                      return DropdownMenuItem<String>(
                        value: shop['id'],
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((shop['address'] ?? '').isNotEmpty)
                              Text(
                                shop['address'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.ink.withOpacityValue(0.6),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedShopId = value;
                        _selectedShopName = shops.firstWhere(
                          (shop) => shop['id'] == value,
                          orElse: () => {'name': 'Unknown'},
                        )['name'];
                        _selectedCategory = 'All';
                        _searchQuery = '';
                        _searchController.clear();
                        _filterUnder150 = false;
                        _filterDairyFree = false;
                        _filterCaffeineBoost = false;
                        _filterSnacks = false;
                      });

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && value != null) {
                        await _firestore
                            .collection('users')
                            .doc(user.uid)
                            .update({
                              'shopId': value,
                              'shopName': _selectedShopName,
                            });
                      }
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuHeader(List<String> categories) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityValue(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Search menu items',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Under ₹150'),
          selected: _filterUnder150,
          onSelected: (value) => setState(() => _filterUnder150 = value),
        ),
        FilterChip(
          label: const Text('Dairy-Free'),
          selected: _filterDairyFree,
          onSelected: (value) => setState(() => _filterDairyFree = value),
        ),
        FilterChip(
          label: const Text('Caffeine Boost'),
          selected: _filterCaffeineBoost,
          onSelected: (value) => setState(() => _filterCaffeineBoost = value),
        ),
        FilterChip(
          label: const Text('Snacks'),
          selected: _filterSnacks,
          onSelected: (value) => setState(() => _filterSnacks = value),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _MenuHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _MenuHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _MenuHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}
