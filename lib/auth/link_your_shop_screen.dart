import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/coffee_data.dart';
import '../core/app_colors.dart';

class LinkYourShopScreen extends StatefulWidget {
  const LinkYourShopScreen({super.key});

  @override
  State<LinkYourShopScreen> createState() => _LinkYourShopScreenState();
}

class _LinkYourShopScreenState extends State<LinkYourShopScreen> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _openingController = TextEditingController();
  final TextEditingController _closingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<void> _createShop() async {
    if (_shopNameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      DocumentReference shopRef = _firestore.collection('shops').doc();
      await shopRef.set({
        'shopId': shopRef.id,
        'name': _shopNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'openingTime': _openingController.text.trim(),
        'closingTime': _closingController.text.trim(),
        'description': _descriptionController.text.trim(),
        'ownerId': user.uid,
        'status': 'offline',
        'menuVersion': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      WriteBatch batch = _firestore.batch();
      for (var coffee in coffeeList) {
        DocumentReference menuItemRef = shopRef.collection('menu').doc();
        batch.set(menuItemRef, {
          'name': coffee.name,
          'price': int.parse(coffee.price),
          'imageUrl': coffee.image,
          'category': coffee.category,
          'description': coffee.description,
          'nutrition': {
            'kcal': coffee.nutrition.kcal,
            'protein': coffee.nutrition.protein,
            'carbs': coffee.nutrition.carbs,
            'fat': coffee.nutrition.fat,
            'caffeineMg': coffee.nutrition.caffeineMg,
          },
          'isSnack': coffee.isSnack,
          'badges': coffee.badges,
          'isDairyFree': coffee.isDairyFree,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      await _firestore.collection('users').doc(user.uid).update({
        'shopId': shopRef.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop linked successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/manage-shop');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create shop: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.crema, AppColors.oat],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link your shop',
                  style: textTheme.displaySmall?.copyWith(
                    color: AppColors.espresso,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bring your menu online in minutes.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink.withOpacityValue(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Image.asset('assets/Icon.png', height: 60),
                        const SizedBox(height: 20),
                        _inputField(
                          'Shop Name',
                          controller: _shopNameController,
                          icon: Icons.storefront_outlined,
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          'Address',
                          controller: _addressController,
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          'City',
                          controller: _cityController,
                          icon: Icons.location_city_outlined,
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          'Phone',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _inputField(
                                'Opening Time',
                                controller: _openingController,
                                icon: Icons.schedule,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _inputField(
                                'Closing Time',
                                controller: _closingController,
                                icon: Icons.schedule_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _descriptionController,
                          minLines: 3,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Short description about your shop',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createShop,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Create Shop'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint, {
    TextEditingController? controller,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _openingController.dispose();
    _closingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
