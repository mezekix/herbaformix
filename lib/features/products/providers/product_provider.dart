import 'dart:async'; // StreamSubscription için

import 'package:flutter/foundation.dart';

import '../../../models/product_model.dart';
import '../../../services/firestore_service.dart';

class ProductProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  StreamSubscription<List<ProductModel>>?
  _productsSubscription; // Stream'i dinlemek için

  bool _isDisposed = false;

  ProductProvider(this._firestoreService) {
    fetchProducts(); // Provider oluşturulduğunda ürünleri çekmeye başla
  }

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void fetchProducts() {
    _isLoading = true;
    scheduleMicrotask(() => safeNotifyListeners());

    // Önceki dinleyiciyi iptal et (varsa)
    _productsSubscription?.cancel();

    // Firestore'dan gelen stream'i dinle
    _productsSubscription = _firestoreService.getProducts().listen(
      (productsData) {
        _products = productsData;
        _isLoading = false;
        safeNotifyListeners(); // UI'ı güncelle
      },
      onError: (error) {
        debugPrint("ProductProvider Hata: $error");
        _isLoading = false;
        _products = []; // Hata durumunda listeyi boşalt
        safeNotifyListeners();
      },
    );
  }

  /// Ürünleri asenkron olarak yükler ve listenin dolmasını bekler.
  Future<void> loadProducts() async {
    fetchProducts();
    int attempts = 0;
    while (_products.isEmpty && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestoreService.addProduct(product);
      // Stream will auto-update the list. No need to call notifyListeners unless for other UI changes.
    } catch (e) {
      debugPrint("ProductProvider Hata (addProduct): $e");
      rethrow;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestoreService.updateProduct(product);
      // Stream will auto-update the list.
    } catch (e) {
      debugPrint("ProductProvider Hata (updateProduct): $e");
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestoreService.deleteProduct(productId);
      // The stream will update the list, so we just show a confirmation or handle errors.
      // No need to call notifyListeners() if the list is the only thing changing,
      // as the stream handles it. But good for other UI feedback.
    } catch (e) {
      debugPrint("ProductProvider Hata (deleteProduct): $e");
      // Optionally, re-throw the error to be caught in the UI layer.
      rethrow;
    }
  }

  // Provider yok edildiğinde StreamSubscription'ı iptal etmeyi unutma!
  @override
  void dispose() {
    _isDisposed = true;
    _productsSubscription?.cancel();
    super.dispose();
  }
}
