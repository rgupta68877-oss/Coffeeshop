import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import '../core/app_colors.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? selectedPayment;
  bool _isPlacingOrder = false;
  String? _paymentReference;
  bool _isLoadingProfile = true;

  final TextEditingController _addressLine1Controller =
      TextEditingController();
  final TextEditingController _addressLine2Controller =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _deliveryNoteController =
      TextEditingController();

  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();

  bool _saveAddress = true;
  bool _saveCard = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final address = data['deliveryAddress'];
      if (address is Map<String, dynamic>) {
        _addressLine1Controller.text = address['line1'] ?? '';
        _addressLine2Controller.text = address['line2'] ?? '';
        _cityController.text = address['city'] ?? '';
        _pincodeController.text = address['pincode'] ?? '';
        _deliveryNoteController.text = address['note'] ?? '';
      }
      final payment = data['paymentProfile'];
      if (payment is Map<String, dynamic>) {
        _cardNameController.text = payment['cardHolder'] ?? '';
        _cardNumberController.text = payment['cardLast4'] != null
            ? '**** **** **** ${payment['cardLast4']}'
            : '';
      }
    }
    if (mounted) {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _placeOrder() async {
    if (selectedPayment == null) return;
    if (_addressLine1Controller.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _pincodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your delivery address')),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final cartState = ref.read(cartProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      if (selectedPayment == 'Cash on Delivery') {
        _paymentReference = null;
      }
      if (selectedPayment == 'UPI / Card Payment') {
        final paid = await _showFakePaymentGateway(
          amount: cartState.totalAmount,
        );
        if (!paid) {
          if (mounted) {
            setState(() {
              _isPlacingOrder = false;
            });
          }
          return;
        }
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final shopId = userData['shopId'];

      final shopDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .get();

      if (!shopDoc.exists) return;

      final shopData = shopDoc.data()!;

      final orderItems = cartState.items
          .map(
            (item) => OrderItem(
              itemId: item.coffee.itemId,
              name: item.coffee.name,
              price: double.parse(item.coffee.price),
              qty: item.qty,
              notes: item.notes,
            ),
          )
          .toList();

      final deliveryAddress = {
        'line1': _addressLine1Controller.text.trim(),
        'line2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'note': _deliveryNoteController.text.trim(),
      };

      final cleanedCardNumber =
          _cardNumberController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final cardLast4 = cleanedCardNumber.length >= 4
          ? cleanedCardNumber.substring(cleanedCardNumber.length - 4)
          : cleanedCardNumber;

      if (_saveAddress) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'deliveryAddress': deliveryAddress}, SetOptions(merge: true));
      }
      if (_saveCard && cardLast4.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'paymentProfile': {
                'cardHolder': _cardNameController.text.trim(),
                'cardLast4': cardLast4,
              },
            }, SetOptions(merge: true));
      }

      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;
      final order = OrderModel(
        orderId: orderId,
        shopId: shopId,
        shopName: shopData['name'] ?? 'Unknown Shop',
        customerId: user.uid,
        customerName: userData['name'] ?? 'Unknown Customer',
        customerPhone: userData['phone'] ?? '',
        items: orderItems,
        totalAmount: cartState.totalAmount,
        status: 'new',
        statusHistory: [
          StatusHistory(status: 'new', time: DateTime.now().toString()),
        ],
        createdAt: DateTime.now().toString(),
      );

      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        ...order.toJson(),
        'deliveryAddress': deliveryAddress,
        'paymentDetails': cardLast4.isEmpty
            ? null
            : {
                'cardHolder': _cardNameController.text.trim(),
                'cardLast4': cardLast4,
              },
        'paymentMethod': selectedPayment,
        'paymentStatus':
            selectedPayment == 'Cash on Delivery' ? 'pending' : 'paid',
        'paymentReference': _paymentReference,
        'createdAt': FieldValue.serverTimestamp(),
      });

      cartNotifier.clearCart();

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/order-success',
          arguments: orderId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  Future<bool> _showFakePaymentGateway({required double amount}) async {
    final reference = 'FAKE-${DateTime.now().millisecondsSinceEpoch}';
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _FakePaymentSheet(amount: amount),
    );
    if (result == true) {
      _paymentReference = reference;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _deliveryNoteController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
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
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Address',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressLine1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressLine2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 2 (Optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Pincode'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deliveryNoteController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Note (Optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Save this address'),
                    value: _saveAddress,
                    onChanged: (value) {
                      setState(() => _saveAddress = value);
                    },
                    activeThumbColor: AppColors.matcha,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Payment Method',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PaymentOptionCard(
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when your coffee arrives.',
                    icon: Icons.payments_outlined,
                    isSelected: selectedPayment == 'Cash on Delivery',
                    onTap: () {
                      setState(() {
                        selectedPayment = 'Cash on Delivery';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _PaymentOptionCard(
                    title: 'UPI / Card Payment',
                    subtitle: 'Instant, secure digital payment.',
                    icon: Icons.credit_card,
                    isSelected: selectedPayment == 'UPI / Card Payment',
                    onTap: () {
                      setState(() {
                        selectedPayment = 'UPI / Card Payment';
                      });
                    },
                  ),
                  if (selectedPayment == 'UPI / Card Payment') ...[
                    const SizedBox(height: 16),
                    Text(
                      'Card Details (Optional)',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cardNameController,
                      decoration: const InputDecoration(
                        labelText: 'Card Holder Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cardExpiryController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Expiry (MM/YY)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _cardCvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'CVV'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Save card for next time'),
                      value: _saveCard,
                      onChanged: (value) {
                        setState(() => _saveCard = value);
                      },
                      activeThumbColor: AppColors.matcha,
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacityValue(0.08),
                blurRadius: 16,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedPayment == null || _isPlacingOrder
                  ? null
                  : _placeOrder,
              child: _isPlacingOrder
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      selectedPayment == 'UPI / Card Payment'
                          ? 'Pay & Place Order'
                          : 'Place Order',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.oat : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.espresso
                : AppColors.espresso.withOpacityValue(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacityValue(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.espresso.withOpacityValue(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.espresso),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.ink.withOpacityValue(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.matcha),
          ],
        ),
      ),
    );
  }
}

class _FakePaymentSheet extends StatefulWidget {
  final double amount;

  const _FakePaymentSheet({required this.amount});

  @override
  State<_FakePaymentSheet> createState() => _FakePaymentSheetState();
}

class _FakePaymentSheetState extends State<_FakePaymentSheet> {
  bool _isProcessing = false;
  String _method = 'UPI';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fake Payment Gateway',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete a dummy payment to proceed.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.ink.withOpacityValue(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: const Text('UPI'),
                selected: _method == 'UPI',
                onSelected: (_) => setState(() => _method = 'UPI'),
              ),
              ChoiceChip(
                label: const Text('Card'),
                selected: _method == 'Card',
                onSelected: (_) => setState(() => _method = 'Card'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: _method == 'UPI' ? 'UPI ID' : 'Card Number',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: _method == 'UPI' ? 'UPI PIN' : 'Expiry (MM/YY)',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      await Future.delayed(const Duration(seconds: 2));
                      if (!mounted) return;
                      Navigator.pop(context, true);
                    },
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('${'\u{20B9}'}${widget.amount.toStringAsFixed(2)} Pay'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
}
}
