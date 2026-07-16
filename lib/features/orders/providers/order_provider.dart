import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../models/scheduled_follow_up_model.dart';

import '../../../models/customer_model.dart';
import '../../../models/order_model.dart'; // OrderStatus enum'ı için
import '../../../models/order_item_model.dart';
import '../../../models/user_role.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart'; // Müşteri bilgisi için
import 'package:herbaformix/core/logger.dart';

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
    _initializeOrders();
  }

  void _initializeOrders() {
    if (_currentUserId != null) {
      final role = _authProvider.userProfile?.role;
      final assignedDistributorId =
          _authProvider.userProfile?.assignedDistributorId;
      if (role == UserRole.customer &&
          assignedDistributorId != null &&
          assignedDistributorId.isNotEmpty) {
        fetchOrders(assignedDistributorId, filterCustomerId: _currentUserId);
      } else {
        fetchOrders(_currentUserId!);
      }
    }
  }

  void _authListener() {
    final newUserId = _authProvider.firebaseUser?.uid;
    if (newUserId != _currentUserId || _orders.isEmpty) {
      _currentUserId = newUserId;
      _ordersSubscription?.cancel();
      _orders = [];
      _initializeOrders();
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

  void fetchOrders(String userId, {String? filterCustomerId}) {
    if (userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _ordersSubscription?.cancel();
    _ordersSubscription = _firestoreService
        .getOrders(userId, customerId: filterCustomerId)
        .listen(
          (ordersData) {
            _orders = ordersData;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            AppLogger.error(
              "OrderProvider Hata (fetchOrders): $error",
              tag: 'OrderProvider',
            );
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
      final role = _authProvider.userProfile?.role;
      final assignedDistributorId =
          _authProvider.userProfile?.assignedDistributorId;
      final targetUserId =
          (role == UserRole.customer &&
              assignedDistributorId != null &&
              assignedDistributorId.isNotEmpty)
          ? assignedDistributorId
          : _currentUserId!;

      final orderWithTotals = OrderModel(
        id: order.id,
        userId: targetUserId,
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
      await _firestoreService.addOrder(targetUserId, orderWithTotals);

      // Yeni sipariş direkt "Teslim Edildi" olarak oluşturulduysa takip planı oluştur
      if (order.status == OrderStatus.delivered) {
        final CustomerModel? customer = await _customerProvider.getCustomerById(
          order.customerId,
        );
        if (customer != null) {
          await _createStandardFollowUpSchedule(customer, items: order.items);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(
        "OrderProvider Hata (addOrder): $e",
        tag: 'OrderProvider',
        error: e,
      );
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
      final role = _authProvider.userProfile?.role;
      final assignedDistributorId =
          _authProvider.userProfile?.assignedDistributorId;
      final targetUserId =
          (role == UserRole.customer &&
              assignedDistributorId != null &&
              assignedDistributorId.isNotEmpty)
          ? assignedDistributorId
          : _currentUserId!;

      // Önce veritabanını güncelle.
      await _firestoreService.updateOrder(targetUserId, order);

      // --- OTOMATİK TAKİP OLUŞTURMA MANTIĞI ---
      // Eğer yeni durum "Teslim Edildi" ise, planı oluştur.
      if (order.status == OrderStatus.delivered) {
        AppLogger.info(
          'Sipariş Teslim Edildi olarak güncellendi. Takip planı oluşturuluyor...',
          tag: 'OrderProvider',
        );

        final CustomerModel? customer = await _customerProvider.getCustomerById(
          order.customerId,
        );

        if (customer != null) {
          AppLogger.info(
            'Müşteri için takip planı oluşturma metodu çağrılıyor',
            tag: 'OrderProvider',
          );
          await _createStandardFollowUpSchedule(customer, items: order.items);
        } else {
          AppLogger.error(
            'Takip planı oluşturulamadı — müşteri bulunamadı',
            tag: 'OrderProvider',
          );
        }
      }

      _isLoading = false;
      notifyListeners(); // isLoading durumu için
      return true;
    } catch (e) {
      AppLogger.error(
        "OrderProvider Hata (updateOrder): $e",
        tag: 'OrderProvider',
        error: e,
      );
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
  Future<void> _createStandardFollowUpSchedule(
    CustomerModel customer, {
    List<OrderItemModel>? items,
  }) async {
    if (_currentUserId == null) return;

    // consultantId boşsa mevcut kullanıcıyı kullan
    final consultantId = customer.consultantId.isNotEmpty
        ? customer.consultantId
        : _currentUserId!;

    // Güvenlik: başka bir danışmanın müşterisine takip oluşturma
    if (consultantId != _currentUserId) {
      AppLogger.error(
        'Takip planı oluşturulamıyor — müşteri başka bir danışmana ait',
        tag: 'OrderProvider',
      );
      return;
    }

    final firstItemName = (items != null && items.isNotEmpty)
        ? items.first.productName
        : '';
    final now = DateTime.now();
    final scheduleDays = [1, 3, 7, 15, 30];
    final List<ScheduledFollowUpModel> followUpBatch = [];

    for (var day in scheduleDays) {
      final followUpTitle = firstItemName.isNotEmpty
          ? '$firstItemName - $day. Gün Kontrolü'
          : '$day. Gün Kontrolü';
      followUpBatch.add(
        ScheduledFollowUpModel(
          id: '',
          consultantId: consultantId,
          customerId: customer.id,
          customerFirstName: customer.firstName,
          customerLastName: customer.lastName,
          dueDate: Timestamp.fromDate(now.add(Duration(days: day))),
          title: followUpTitle,
          isCompleted: false,
          isAutoGenerated: true,
          createdAt: Timestamp.now(),
        ),
      );
    }

    try {
      await _firestoreService.addScheduledFollowUpBatch(followUpBatch);
      AppLogger.info(
        'Müşteri için takip planı oluşturuldu',
        tag: 'OrderProvider',
      );
    } catch (e) {
      AppLogger.error(
        "HATA: Takip planı oluşturulurken hata: $e",
        tag: 'OrderProvider',
        error: e,
      );
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
      AppLogger.error(
        "OrderProvider Hata (deleteOrder): $e",
        tag: 'OrderProvider',
        error: e,
      );
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
