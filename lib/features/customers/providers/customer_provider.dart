import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/customer_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

class CustomerProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthProvider _authProvider;

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  StreamSubscription<List<CustomerModel>>? _customersSubscription;
  String? _currentUserId;

  CustomerProvider(this._firestoreService, this._authProvider) {
    _currentUserId = _authProvider.firebaseUser?.uid;
    _authProvider.addListener(_authListener);
    if (_currentUserId != null) {
      fetchCustomers(_currentUserId!);
    }
  }

  void _authListener() {
    final newUserId = _authProvider.firebaseUser?.uid;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _customersSubscription?.cancel();
      _customers = [];
      if (_currentUserId != null) {
        fetchCustomers(_currentUserId!);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;

  // Müşteri sayısını döndüren getter
  int get customersCount => _customers.length;

  void fetchCustomers(String userId) {
    if (userId.isEmpty) {
      _customers = [];
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    _customersSubscription?.cancel();
    _customersSubscription = _firestoreService
        .getCustomers(userId)
        .listen(
          (customersData) {
            _customers = customersData;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint("CustomerProvider Hata (fetchCustomers): $error");
            _isLoading = false;
            _customers = [];
            notifyListeners();
          },
        );
  }

  Future<bool> addCustomer(CustomerModel customer) async {
    if (_currentUserId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final customerToAdd = CustomerModel(
        id: '', // Firestore ID'yi kendi verecek
        firstName: customer.firstName,
        lastName: customer.lastName,
        phoneNumber: customer.phoneNumber,
        email: customer.email,
        address: customer.address,
        firstContactDate: customer.firstContactDate,
        consultantId: _currentUserId!, // Sağlayıcıdaki güncel kullanıcıyı ata
        isActive: customer.isActive,
        notes: customer.notes,
      );
      await _firestoreService.addCustomer(_currentUserId!, customerToAdd);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("CustomerProvider Hata (addCustomer): $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    if (_currentUserId == null || customer.consultantId != _currentUserId) {
      return false;
    }
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updateCustomer(_currentUserId!, customer);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("CustomerProvider Hata (updateCustomer): $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    if (_currentUserId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.deleteCustomer(_currentUserId!, customerId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("CustomerProvider Hata (deleteCustomer): $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Belirtilen ID'ye sahip müşteriyi getirir.
  /// Önce lokalde yüklü olan listede arar. Bulamazsa, doğrudan
  /// veritabanından bu tek müşteriyi çekmeyi dener.
  /// Bu, provider'lar arası zamanlama sorunlarını (race condition) çözer.
  Future<CustomerModel?> getCustomerById(String customerId) async {
    if (_currentUserId == null) return null;

    // 1. Önce lokalde, hafızadaki listede ara.
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      return customer;
    } catch (e) {
      // Lokal listede bulunamadı, bu beklenen bir durum olabilir.
      // Şimdi veritabanından çekmeyi deneyeceğiz.
      debugPrint(
        "Müşteri lokalde bulunamadı ($customerId), veritabanından çekiliyor...",
      );
    }

    // 2. Lokal listede yoksa, doğrudan Firestore'dan çek.
    try {
      final customer = await _firestoreService.getCustomer(
        _currentUserId!,
        customerId,
      );
      return customer;
    } catch (e) {
      debugPrint("CustomerProvider Hata (getCustomerById): $e");
      return null;
    }
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    _authProvider.removeListener(_authListener);
    super.dispose();
  }
}
