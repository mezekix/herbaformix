import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../models/order_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

class OrderProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthProvider _authProvider;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  String? _currentUserId;

  OrderProvider(this._firestoreService, this._authProvider) {
    _currentUserId = _authProvider.firebaseUser?.uid;
    _authProvider.addListener(_authListener);
    if (_currentUserId != null) {
      fetchOrders(_currentUserId!);
    }
  }

  void _authListener() {
    final newUserId = _authProvider.firebaseUser?.uid;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _ordersSubscription?.cancel();
      _orders = [];
      if (_currentUserId != null) {
        fetchOrders(_currentUserId!);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  void fetchOrders(String userId) {
    if (userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _ordersSubscription?.cancel();
    _ordersSubscription = _firestoreService.getOrders(userId).listen((ordersData) {
      _orders = ordersData;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _isLoading = false;
      _orders = [];
      notifyListeners();
    });
  }

  Future<bool> addOrder(OrderModel order) async {
    if (_currentUserId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.addOrder(_currentUserId!, order);
      _isLoading = false;
      notifyListeners(); // Stream otomatik güncelleyeceği için burada listeyi elle değiştirmeye gerek yok
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (_currentUserId == null) return false;
    // Siparişi bul ve status'u güncelle, sonra Firestore'a gönder
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      _orders[orderIndex].status = newStatus;
      try {
        await _firestoreService.updateOrder(_currentUserId!, _orders[orderIndex]);
        notifyListeners();
        return true;
      } catch (e) {
        // Hata durumunda eski status'e geri dönülebilir veya hata mesajı gösterilebilir
        return false;
      }
    }
    return false;
  }


  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _authProvider.removeListener(_authListener);
    super.dispose();
  }
}