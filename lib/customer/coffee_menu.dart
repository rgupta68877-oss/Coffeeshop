import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
      ),
    );
  }
}
