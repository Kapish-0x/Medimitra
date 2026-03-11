import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String category;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.category,
    this.quantity = 1,
  });

  double get total => price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => Map.unmodifiable(_items);
  List<CartItem> get itemList => _items.values.toList();
  int get itemCount => _items.length;
  int get totalQty => _items.values.fold(0, (s, i) => s + i.quantity);

  double get subtotal =>
      _items.values.fold(0, (sum, item) => sum + item.total);

  double get total => subtotal; // add delivery fee logic if needed

  bool contains(String id) => _items.containsKey(id);

  void addItem({
    required String id,
    required String name,
    required String brand,
    required double price,
    required String category,
  }) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
    } else {
      _items[id] = CartItem(
        id: id,
        name: name,
        brand: brand,
        price: price,
        category: category,
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void increment(String id) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
      notifyListeners();
    }
  }

  void decrement(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantity <= 1) {
      _items.remove(id);
    } else {
      _items[id]!.quantity--;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderItems() {
    return _items.values
        .map((i) => {'medicineId': i.id, 'quantity': i.quantity})
        .toList();
  }
}
