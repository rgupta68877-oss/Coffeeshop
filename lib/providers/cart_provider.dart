import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/coffee_data.dart';

@immutable
class CartItem {
  final Coffee coffee;
  final String notes;
  final int qty;

  const CartItem({
    required this.coffee,
    this.notes = '',
    this.qty = 1,
  });

  double get total => double.parse(coffee.price) * qty;

  CartItem copyWith({int? qty}) {
    return CartItem(
      coffee: coffee,
      notes: notes,
      qty: qty ?? this.qty,
    );
  }
}

@immutable
class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  int get itemCount => items.length;

  int get totalQty => items.fold(0, (sum, item) => sum + item.qty);

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.total);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(Coffee coffee, {String notes = ''}) {
    final index = state.items.indexWhere(
      (item) => item.coffee.itemId == coffee.itemId && item.notes == notes,
    );
    if (index >= 0) {
      final updated = [...state.items];
      final item = updated[index];
      updated[index] = item.copyWith(qty: item.qty + 1);
      state = CartState(items: updated);
      return;
    }
    state = CartState(items: [
      ...state.items,
      CartItem(coffee: coffee, notes: notes),
    ]);
  }

  void removeItem(String itemId, {String notes = ''}) {
    state = CartState(
      items: state.items
          .where(
            (item) =>
                !(item.coffee.itemId == itemId && item.notes == notes),
          )
          .toList(),
    );
  }

  void updateQty(String itemId, int qty, {String notes = ''}) {
    final updated = <CartItem>[];
    for (final item in state.items) {
      if (item.coffee.itemId == itemId && item.notes == notes) {
        if (qty > 0) {
          updated.add(item.copyWith(qty: qty));
        }
      } else {
        updated.add(item);
      }
    }
    state = CartState(items: updated);
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
