import 'dart:async'; // StreamSubscription için

import 'package:flutter/foundation.dart';
import 'package:herbaformix/core/logger.dart';

import '../../../models/product_model.dart';
import '../../../models/user_role.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProductProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthProvider? _authProvider;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  StreamSubscription<List<ProductModel>>? _productsSubscription;
  String? _activeUserId;
  UserRole? _activeRole;

  bool _isDisposed = false;

  ProductProvider(this._firestoreService, {AuthProvider? authProvider})
      : _authProvider = authProvider {
    _authProvider?.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void fetchProducts() {
    final currentUserId = _authProvider?.firebaseUser?.uid;
    final currentRole = _authProvider?.userProfile?.role;
    if (_authProvider != null && currentUserId == null) {
      _productsSubscription?.cancel();
      _productsSubscription = null;
      _activeUserId = null;
      _activeRole = null;
      _products = [];
      _isLoading = false;
      scheduleMicrotask(() => safeNotifyListeners());
      return;
    }

    if (_authProvider != null && currentRole == null) {
      _productsSubscription?.cancel();
      _productsSubscription = null;
      _activeUserId = currentUserId;
      _activeRole = null;
      _products = [];
      _isLoading = true;
      scheduleMicrotask(() => safeNotifyListeners());
      return;
    }

    _activeUserId = currentUserId;
    _activeRole = currentRole;
    _isLoading = true;
    scheduleMicrotask(() => safeNotifyListeners());

    // Önceki dinleyiciyi iptal et (varsa)
    _productsSubscription?.cancel();

    // Firestore'dan gelen stream'i dinle
    _productsSubscription = _firestoreService
        .getProducts(customerVisibleOnly: currentRole == UserRole.customer)
        .listen(
      (productsData) {
        _products = productsData;
        _isLoading = false;
        safeNotifyListeners(); // UI'ı güncelle
      },
      onError: (error) {
        AppLogger.error("ProductProvider Hata: $error", tag: 'ProductProvider');
        _isLoading = false;
        _products = []; // Hata durumunda listeyi boşalt
        safeNotifyListeners();
      },
    );
  }

  void _handleAuthChanged() {
    final currentUserId = _authProvider?.firebaseUser?.uid;
    final currentRole = _authProvider?.userProfile?.role;
    if (currentUserId == _activeUserId &&
        currentRole == _activeRole &&
        _productsSubscription != null) {
      return;
    }
    fetchProducts();
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
      AppLogger.error("ProductProvider Hata (addProduct): $e", tag: 'ProductProvider', error: e);
      rethrow;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestoreService.updateProduct(product);
      // Stream will auto-update the list.
    } catch (e) {
      AppLogger.error("ProductProvider Hata (updateProduct): $e", tag: 'ProductProvider', error: e);
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
      AppLogger.error("ProductProvider Hata (deleteProduct): $e", tag: 'ProductProvider', error: e);
      // Optionally, re-throw the error to be caught in the UI layer.
      rethrow;
    }
  }

  // Provider yok edildiğinde StreamSubscription'ı iptal etmeyi unutma!
  @override
  void dispose() {
    _isDisposed = true;
    _authProvider?.removeListener(_handleAuthChanged);
    _productsSubscription?.cancel();
    super.dispose();
  }
}
