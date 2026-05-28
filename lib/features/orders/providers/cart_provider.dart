import 'package:flutter/material.dart';
import '../../../models/order_item_model.dart';
import '../../../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, OrderItemModel> _items = {};

  Map<String, OrderItemModel> get items => _items;

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalVp => _items.values.fold(0.0, (sum, item) => sum + item.totalVp);

  void addItem(ProductModel product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => OrderItemModel(
          productId: existing.productId,
          productName: existing.productName,
          quantity: existing.quantity + quantity,
          unitPrice: existing.unitPrice,
          unitVp: existing.unitVp,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => OrderItemModel(
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          unitPrice: product.price ?? 0.0,
          unitVp: product.vp,
        ),
      );
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => OrderItemModel(
          productId: existing.productId,
          productName: existing.productName,
          quantity: quantity,
          unitPrice: existing.unitPrice,
          unitVp: existing.unitVp,
        ),
      );
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
