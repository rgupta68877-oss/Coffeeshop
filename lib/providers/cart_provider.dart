import 'package:flutter/material.dart';
import '../widgets/coffee_data.dart';

class CartItem {
  final Coffee coffee;
  int qty;

  CartItem({required this.coffee, this.qty = 1});

  double get total => double.parse(coffee.price) * qty;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  int get totalQty => _items.fold(0, (sum, item) => sum + item.qty);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.total);

  void addItem(Coffee coffee) {
    final existingIndex = _items.indexWhere(
      (item) => item.coffee.itemId == coffee.itemId,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].qty++;
    } else {
      _items.add(CartItem(coffee: coffee));
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.coffee.itemId == itemId);
    notifyListeners();
  }

  void updateQty(String itemId, int qty) {
    final index = _items.indexWhere((item) => item.coffee.itemId == itemId);
    if (index >= 0) {
      if (qty > 0) {
        _items[index].qty = qty;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
