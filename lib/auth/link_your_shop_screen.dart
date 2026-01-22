import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/coffee_data.dart';

class LinkYourShopScreen extends StatefulWidget {
  const LinkYourShopScreen({super.key});

  @override
  State<LinkYourShopScreen> createState() => _LinkYourShopScreenState();
}

class _LinkYourShopScreenState extends State<LinkYourShopScreen> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<void> _createShop() async {
    if (_shopNameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
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

      // Create shop document
      DocumentReference shopRef = _firestore.collection('shops').doc();
      await shopRef.set({
        'shopId': shopRef.id,
        'name': _shopNameController.text.trim(),
        'address': _addressController.text.trim(),
        'ownerId': user.uid,
        'status': 'offline',
        'menuVersion': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Initialize menu with fixed items
      WriteBatch batch = _firestore.batch();
      for (var coffee in coffeeList) {
        DocumentReference menuItemRef = shopRef.collection('menu').doc();
        batch.set(menuItemRef, {
          'name': coffee.name,
          'price': int.parse(coffee.price),
          'imageUrl': coffee.image,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Update user document with shopId
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C1A0F), Color(0xFF6F4E37)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', height: 100),
                    const SizedBox(height: 30),
                    const Text(
                      'Link Your Shop',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6F4E37),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _inputField("Shop Name", controller: _shopNameController),
                    const SizedBox(height: 16),
                    _inputField("Address", controller: _addressController),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC47A45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _createShop,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Create Shop",
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint, {
    TextEditingController? controller,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
