import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/order_model.dart'; // OrderStatus enum'ı için
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

  // Bu ay kazanılan toplam VP'yi hesapla (Teslim edildi veya Kargolandı durumundaki siparişlerden)
  double get totalVpEarnedThisMonth {
    if (_orders.isEmpty) return 0.0;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(
      now.year,
      now.month + 1,
      0,
      23,
      59,
      59,
    ); // Ayın son günü

    return _orders
        .where(
          (order) =>
              (order.status == OrderStatus.delivered ||
                  order.status == OrderStatus.shipped) &&
              order.orderDate.toDate().isAfter(
                firstDayOfMonth.subtract(const Duration(days: 1)),
              ) && // Ayın başından sonra
              order.orderDate.toDate().isBefore(
                lastDayOfMonth.add(const Duration(days: 1)),
              ),
        ) // Ayın sonundan önce
        .fold(0.0, (sum, order) => sum + order.totalVpEarned);
  }

  // Beklemede olan sipariş sayısını al
  int get pendingOrdersCount {
    if (_orders.isEmpty) return 0;
    return _orders
        .where(
          (order) =>
              order.status == OrderStatus.pending ||
              order.status == OrderStatus.processing,
        )
        .length;
  }

  void fetchOrders(String userId) {
    if (userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _ordersSubscription?.cancel();
    _ordersSubscription = _firestoreService
        .getOrders(userId)
        .listen(
          (ordersData) {
            _orders = ordersData;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            print("OrderProvider Hata (fetchOrders): $error");
            _isLoading = false;
            _orders = [];
            notifyListeners();
          },
        );
  }

  Future<bool> addOrder(OrderModel order) async {
    if (_currentUserId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      // Firestore servisine göndermeden önce totalAmount ve totalVpEarned'ı hesapla
      final orderWithTotals = OrderModel(
        id: order.id,
        userId: _currentUserId!,
        customerId: order.customerId,
        customerName: order.customerName,
        items: order.items,
        orderDate: order.orderDate,
        status: order.status,
        totalAmount: order.items.fold(
          0.0,
          (sum, item) => sum + item.totalPrice,
        ),
        totalVpEarned: order.items.fold(0.0, (sum, item) => sum + item.totalVp),
        notes: order.notes,
        shippingAddress: order.shippingAddress,
      );
      await _firestoreService.addOrder(_currentUserId!, orderWithTotals);
      _isLoading = false;
      // Stream zaten listeyi güncelleyeceği için burada notifyListeners'a gerek yok,
      // ancak _isLoading durumu için çağrılabilir.
      notifyListeners();
      return true;
    } catch (e) {
      print("OrderProvider Hata (addOrder): $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (_currentUserId == null) return false;
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      // Siparişin bir kopyasını oluşturup status'u güncelle
      OrderModel updatedOrder = _orders[orderIndex];
      updatedOrder.status = newStatus;

      try {
        await _firestoreService.updateOrder(_currentUserId!, updatedOrder);
        // Stream güncelleyeceği için lokal listeyi burada değiştirmeye gerek yok,
        // ama anlık UI tepkisi için yapılabilir.
        // _orders[orderIndex] = updatedOrder; // Eğer stream anında güncellemiyorsa
        notifyListeners();
        return true;
      } catch (e) {
        print("OrderProvider Hata (updateOrderStatus): $e");
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
