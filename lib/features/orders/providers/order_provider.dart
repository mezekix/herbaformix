import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../models/scheduled_follow_up_model.dart';

import '../../../models/customer_model.dart';
import '../../../models/order_model.dart'; // OrderStatus enum'ı için
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart'; // Müşteri bilgisi için

class OrderProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthProvider _authProvider;
  final CustomerProvider _customerProvider; // CustomerProvider'ı ekliyoruz.

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  String? _currentUserId;

  OrderProvider(
    this._firestoreService,
    this._authProvider,
    this._customerProvider,
  ) {
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
        .fold(0.0, (total, order) => total + order.totalVpEarned);
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
            debugPrint("OrderProvider Hata (fetchOrders): $error");
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
          (total, item) => total + item.totalPrice,
        ),
        totalVpEarned: order.items.fold(
          0.0,
          (total, item) => total + item.totalVp,
        ),
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
      debugPrint("OrderProvider Hata (addOrder): $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mevcut bir siparişin tüm verilerini günceller.
  /// Eğer bu güncelleme sırasında siparişin durumu 'Teslim Edildi' olarak değiştiyse,
  /// otomatik takip planını oluşturur.
  Future<bool> updateOrder(OrderModel order) async {
    if (_currentUserId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      // Önce veritabanını güncelle.
      await _firestoreService.updateOrder(_currentUserId!, order);

      // --- OTOMATİK TAKİP OLUŞTURMA MANTIĞI ---
      // Eğer yeni durum "Teslim Edildi" ise, planı oluştur.
      if (order.status == OrderStatus.delivered) {
        debugPrint(
          "Sipariş 'Teslim Edildi' olarak güncellendi. Takip planı oluşturuluyor...",
        );

        final CustomerModel? customer = await _customerProvider.getCustomerById(
          order.customerId,
        );

        if (customer != null) {
          debugPrint(
            "'${customer.firstName}' için takip planı oluşturma metodu çağrılıyor.",
          );
          await _createStandardFollowUpSchedule(customer);
        } else {
          debugPrint(
            "HATA: Takip planı oluşturulamadı çünkü müşteri ID'si (${order.customerId}) bulunamadı.",
          );
        }
      }

      _isLoading = false;
      notifyListeners(); // isLoading durumu için
      return true;
    } catch (e) {
      debugPrint("OrderProvider Hata (updateOrder): $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sadece bir siparişin durumunu günceller. (Bu metot başka yerlerde kullanılabilir, o yüzden kalmalı)
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      OrderModel orderToUpdate = _orders[orderIndex];
      orderToUpdate.status = newStatus;
      // Artık tüm güncelleme mantığı updateOrder'da olduğu için onu çağırıyoruz.
      return await updateOrder(orderToUpdate);
    }
    return false;
  }

  /// Standart bir takip planı oluşturup veritabanına ekler.
  Future<void> _createStandardFollowUpSchedule(CustomerModel customer) async {
    // Güvenlik kontrolü: Müşterinin danışman ID'si var mı ve mevcut kullanıcıyla eşleşiyor mu?
    if (customer.consultantId.isEmpty ||
        customer.consultantId != _currentUserId) {
      debugPrint(
        "HATA: Otomatik takip planı oluşturulamıyor. Müşteri kaydındaki danışman ID'si ('${customer.consultantId}') mevcut kullanıcı ID'siyle ('$_currentUserId') eşleşmiyor veya boştur.",
      );
      return; // ID'ler eşleşmiyorsa veya boşsa işlemi durdur.
    }
    final now = DateTime.now();
    final scheduleDays = [1, 3, 7, 15, 30]; // Takip edilecek günler.

    final List<ScheduledFollowUpModel> followUpBatch = [];

    for (var day in scheduleDays) {
      followUpBatch.add(
        ScheduledFollowUpModel(
          id: '', // Firestore kendi atayacak.
          consultantId: customer.consultantId,
          customerId: customer.id,
          customerFirstName: customer.firstName,
          customerLastName: customer.lastName,
          dueDate: Timestamp.fromDate(now.add(Duration(days: day))),
          title: '$day. Gün Kontrolü',
          isCompleted: false,
        ),
      );
    }

    try {
      // Oluşturulan tüm görevleri tek bir işlemde veritabanına yaz.
      await _firestoreService.addScheduledFollowUpBatch(followUpBatch);
      debugPrint(
        "BAŞARILI: '${customer.firstName} ${customer.lastName}' için standart takip planı oluşturuldu.",
      );
    } catch (e) {
      debugPrint("HATA: Standart takip planı oluşturulurken hata: $e");
    }
  }

  /// Bir siparişi siler.
  Future<bool> deleteOrder(String orderId) async {
    if (_currentUserId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.deleteOrder(_currentUserId!, orderId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("OrderProvider Hata (deleteOrder): $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _authProvider.removeListener(_authListener);
    super.dispose();
  }
}
