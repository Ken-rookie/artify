import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartStore extends ChangeNotifier {
  CartStore._();
  static final CartStore instance = CartStore._();
  final Map<Product, int> _items = {};
  final Map<Product, int> _stock = {};
  final Set<Product> _wishlist = {};

  Map<Product, int> get items => Map.unmodifiable(_items);
  Set<Product> get wishlist => Set.unmodifiable(_wishlist);
  int get count => _items.values.fold(0, (a, b) => a + b);
  int get subtotal => _items.entries.fold(0, (sum, e) => sum + e.key.price * e.value);
  int stockFor(Product product) =>
      _stock.putIfAbsent(product, () => product.stock);

  bool canAdd(Product product, [int quantity = 1]) =>
      quantity > 0 && (_items[product] ?? 0) + quantity <= stockFor(product);

  bool add(Product product, [int quantity = 1]) {
    if (!canAdd(product, quantity)) return false;
    _items[product] = (_items[product] ?? 0) + quantity;
    notifyListeners();
    return true;
  }

  bool setQuantity(Product product, int quantity) {
    if (quantity > stockFor(product)) return false;
    if (quantity <= 0) {
      _items.remove(product);
    } else {
      _items[product] = quantity;
    }
    notifyListeners();
    return true;
  }

  bool canPurchase(Map<Product, int> products) =>
      products.isNotEmpty &&
      products.entries.every(
        (entry) => entry.value > 0 && entry.value <= stockFor(entry.key),
      );

  bool completePurchase(
    Map<Product, int> products, {
    bool removeFromCart = false,
  }) {
    if (!canPurchase(products)) return false;

    for (final entry in products.entries) {
      final remainingStock = stockFor(entry.key) - entry.value;
      _stock[entry.key] = remainingStock;

      if (removeFromCart) {
        final remainingInCart = (_items[entry.key] ?? 0) - entry.value;
        if (remainingInCart <= 0) {
          _items.remove(entry.key);
        } else {
          _items[entry.key] = remainingInCart;
        }
      }
    }

    for (final entry in _items.entries.toList()) {
      final remainingStock = stockFor(entry.key);
      if (remainingStock == 0) {
        _items.remove(entry.key);
      } else if (entry.value > remainingStock) {
        _items[entry.key] = remainingStock;
      }
    }

    notifyListeners();
    return true;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
  void toggleWishlist(Product p) {
    if (!_wishlist.add(p)) _wishlist.remove(p);
    notifyListeners();
  }
  bool isSaved(Product p) => _wishlist.contains(p);
}
