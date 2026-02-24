import 'dart:async';

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
  bool _isLoadingOffers = false;

  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _deliveryNoteController = TextEditingController();

  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  bool _saveAddress = true;
  bool _saveCard = false;
  bool _useWallet = false;
  bool _redeemLoyalty = false;
  double _walletBalance = 0.0;
  int _loyaltyPoints = 0;
  double _tipAmount = 0.0;
  String? _appliedCouponCode;
  double _discountAmount = 0.0;
  List<Map<String, dynamic>> _availableOffers = [];

  @override
  void initState() {
    super.initState();
    unawaited(_ensureDefaultCoupons());
    _loadProfile();
  }

  Future<void> _ensureDefaultCoupons() async {
    await FirebaseFirestore.instance.collection('coupons').doc('FIRST50').set({
      'code': 'FIRST50',
      'type': 'percent',
      'value': 50,
      'firstOrderOnly': true,
      'isActive': true,
      'label': 'FIRST50 - 50% OFF your first order',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
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
      _walletBalance = (data['walletBalance'] is num)
          ? (data['walletBalance'] as num).toDouble()
          : 0.0;
      _loyaltyPoints = (data['loyaltyPoints'] is num)
          ? (data['loyaltyPoints'] as num).toInt()
          : 0;
      final shopId = (data['shopId'] ?? '').toString();
      if (shopId.isNotEmpty) {
        await _loadOffers(shopId);
      }
    }
    if (mounted) {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadOffers(String shopId) async {
    setState(() => _isLoadingOffers = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .get();
      final offers = snapshot.docs.map((doc) => doc.data()).where((data) {
        final targetShop = (data['shopId'] ?? 'global').toString();
        return targetShop == 'global' || targetShop == shopId;
      }).toList();
      if (!mounted) return;
      setState(() {
        _availableOffers = offers;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingOffers = false);
      }
    }
  }

  double _loyaltyRedeemAmount(double subtotal) {
    if (!_redeemLoyalty) return 0.0;
    final maxRedeem = subtotal - _discountAmount;
    if (maxRedeem <= 0) return 0.0;
    return _loyaltyPoints.toDouble().clamp(0, maxRedeem).toDouble();
  }

  double _walletUsedAmount(double subtotal) {
    if (!_useWallet) return 0.0;
    final afterDiscountAndLoyalty =
        subtotal -
        _discountAmount -
        _loyaltyRedeemAmount(subtotal) +
        _tipAmount;
    if (afterDiscountAndLoyalty <= 0) return 0.0;
    return _walletBalance.clamp(0, afterDiscountAndLoyalty).toDouble();
  }

  double _payableAmount(double subtotal) {
    final amount =
        subtotal +
        _tipAmount -
        _discountAmount -
        _loyaltyRedeemAmount(subtotal) -
        _walletUsedAmount(subtotal);
    return amount < 0 ? 0 : amount;
  }

  Future<void> _applyCoupon(double subtotal) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _appliedCouponCode = null;
        _discountAmount = 0.0;
      });
      return;
    }
    if (code == 'FIRST50') {
      await _applyFirst50Coupon(subtotal);
      return;
    }
    final offer = _availableOffers.firstWhere(
      (item) => (item['code'] ?? '').toString().toUpperCase() == code,
      orElse: () => {},
    );
    if (offer.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid coupon code')));
      return;
    }
    final minOrder = (offer['minOrder'] is num)
        ? (offer['minOrder'] as num).toDouble()
        : 0.0;
    if (subtotal < minOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum order for this coupon is ${'\u{20B9}'}$minOrder',
          ),
        ),
      );
      return;
    }
    final type = (offer['type'] ?? 'flat').toString();
    final value = (offer['value'] is num)
        ? (offer['value'] as num).toDouble()
        : 0.0;
    final discount = type == 'percent' ? (subtotal * value / 100) : value;
    setState(() {
      _appliedCouponCode = code;
      _discountAmount = discount.clamp(0, subtotal).toDouble();
    });
  }

  Future<void> _applyFirst50Coupon(double subtotal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final canUse = await _canUseFirst50Coupon(user.uid);
    if (!canUse) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'FIRST50 is valid only for your first order and can be used once.',
          ),
        ),
      );
      return;
    }

    final couponDoc = await FirebaseFirestore.instance
        .collection('coupons')
        .doc('FIRST50')
        .get();
    if (!couponDoc.exists || couponDoc.data()?['isActive'] != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon FIRST50 is not active right now')),
      );
      return;
    }

    final discount = (subtotal * 0.5).clamp(0, subtotal).toDouble();
    setState(() {
      _appliedCouponCode = 'FIRST50';
      _discountAmount = discount;
    });
  }

  Future<bool> _canUseFirst50Coupon(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final usedCoupons =
        (userDoc.data()?['usedCouponCodes'] as List?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ??
        const <String>[];
    if (usedCoupons.contains('FIRST50')) return false;

    final existingOrder = await FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .limit(1)
        .get();
    return existingOrder.docs.isEmpty;
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
      final subtotal = cartState.totalAmount;
      final loyaltyRedeemed = _loyaltyRedeemAmount(subtotal);
      final walletUsed = _walletUsedAmount(subtotal);
      final payableAmount = _payableAmount(subtotal);
      final loyaltyEarned = (payableAmount / 10).floor();
      if (selectedPayment == 'Cash on Delivery') {
        _paymentReference = null;
      }
      if (selectedPayment == 'UPI / Card Payment') {
        final paid = await _showFakePaymentGateway(amount: payableAmount);
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

      if (_appliedCouponCode == 'FIRST50') {
        final canUse = await _canUseFirst50Coupon(user.uid);
        if (!canUse) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FIRST50 is no longer valid for this account.'),
            ),
          );
          setState(() {
            _appliedCouponCode = null;
            _discountAmount = 0.0;
            _isPlacingOrder = false;
          });
          return;
        }
      }

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

      final cleanedCardNumber = _cardNumberController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final cardLast4 = cleanedCardNumber.length >= 4
          ? cleanedCardNumber.substring(cleanedCardNumber.length - 4)
          : cleanedCardNumber;

      if (_saveAddress) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'deliveryAddress': deliveryAddress,
        }, SetOptions(merge: true));
      }
      if (_saveCard && cardLast4.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
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
        totalAmount: payableAmount,
        status: 'new',
        statusHistory: [
          StatusHistory(status: 'new', time: DateTime.now().toString()),
        ],
        createdAt: DateTime.now().toString(),
      );

      final invoiceId = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final invoice = {
        'invoiceId': invoiceId,
        'generatedAt': DateTime.now().toIso8601String(),
        'items': orderItems.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'discount': _discountAmount,
        'tip': _tipAmount,
        'walletUsed': walletUsed,
        'loyaltyRedeemed': loyaltyRedeemed,
        'total': payableAmount,
      };

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
        'paymentStatus': selectedPayment == 'Cash on Delivery'
            ? 'pending'
            : 'paid',
        'paymentReference': _paymentReference,
        'couponCode': _appliedCouponCode,
        'discountAmount': _discountAmount,
        'tipAmount': _tipAmount,
        'walletUsed': walletUsed,
        'loyaltyRedeemed': loyaltyRedeemed,
        'loyaltyEarned': loyaltyEarned,
        'invoice': invoice,
        'refundStatus': 'none',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newWallet = (_walletBalance - walletUsed).clamp(0, double.infinity);
      final newPoints =
          (_loyaltyPoints - loyaltyRedeemed.toInt() + loyaltyEarned).clamp(
            0,
            1000000,
          );
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'walletBalance': newWallet,
        'loyaltyPoints': newPoints,
        if (_appliedCouponCode != null)
          'usedCouponCodes': FieldValue.arrayUnion([_appliedCouponCode]),
      }, SetOptions(merge: true));

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
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cartState = ref.watch(cartProvider);
    final subtotal = cartState.totalAmount;
    final loyaltyRedeemed = _loyaltyRedeemAmount(subtotal);
    final walletUsed = _walletUsedAmount(subtotal);
    final payable = _payableAmount(subtotal);

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
                          decoration: const InputDecoration(
                            labelText: 'Pincode',
                          ),
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
                            decoration: const InputDecoration(labelText: 'CVV'),
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
                  const SizedBox(height: 14),
                  Text(
                    'Offers & Savings',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingOffers)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  else if (_availableOffers.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableOffers.map((offer) {
                        final code = (offer['code'] ?? '').toString();
                        final label = (offer['label'] ?? code).toString();
                        return ActionChip(
                          label: Text(label),
                          onPressed: () async {
                            setState(() {
                              _couponController.text = code;
                            });
                            await _applyCoupon(subtotal);
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Coupon code',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await _applyCoupon(subtotal);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  if (_appliedCouponCode != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Applied: $_appliedCouponCode (-${'\u{20B9}'}${_discountAmount.toStringAsFixed(2)})',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.matcha,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Use wallet balance (${'\u{20B9}'}${_walletBalance.toStringAsFixed(2)})',
                    ),
                    value: _useWallet,
                    onChanged: (value) => setState(() => _useWallet = value),
                    activeThumbColor: AppColors.matcha,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Redeem loyalty points ($_loyaltyPoints pts)'),
                    value: _redeemLoyalty,
                    onChanged: (value) =>
                        setState(() => _redeemLoyalty = value),
                    activeThumbColor: AppColors.matcha,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add a Tip',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [0.0, 10.0, 20.0, 30.0].map((tip) {
                      final selected = _tipAmount == tip;
                      return ChoiceChip(
                        label: Text(
                          tip == 0 ? 'No Tip' : '${'\u{20B9}'}${tip.toInt()}',
                        ),
                        selected: selected,
                        onSelected: (_) => setState(() => _tipAmount = tip),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _summaryRow('Subtotal', subtotal),
                          _summaryRow('Discount', -_discountAmount),
                          _summaryRow('Loyalty', -loyaltyRedeemed),
                          _summaryRow('Wallet', -walletUsed),
                          _summaryRow('Tip', _tipAmount),
                          const Divider(),
                          _summaryRow('Payable', payable, isBold: true),
                        ],
                      ),
                    ),
                  ),
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
                          ? 'Pay ${'\u{20B9}'}${payable.toStringAsFixed(2)} & Place Order'
                          : 'Place Order',
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    final color = isBold ? AppColors.espresso : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${value < 0 ? '-' : ''}${'\u{20B9}'}${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
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
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                      if (!context.mounted) return;
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
                  : Text(
                      '${'\u{20B9}'}${widget.amount.toStringAsFixed(2)} Pay',
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
