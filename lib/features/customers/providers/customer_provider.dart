import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../models/customer_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart'; // Mevcut kullanıcı ID'sini almak için

class CustomerProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthProvider _authProvider; // AuthProvider'ı ekle

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  StreamSubscription<List<CustomerModel>>? _customersSubscription;
  String? _currentUserId; // Dinlenecek kullanıcı ID'si

  CustomerProvider(this._firestoreService, this._authProvider) {
    // AuthProvider'dan kullanıcı ID'sini dinle
    _currentUserId = _authProvider.firebaseUser?.uid;
    _authProvider.addListener(_authListener); // AuthProvider'daki değişiklikleri dinle
    if (_currentUserId != null) {
      fetchCustomers(_currentUserId!);
    }
  }

  void _authListener() {
    final newUserId = _authProvider.firebaseUser?.uid;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _customersSubscription?.cancel(); // Eski dinleyiciyi iptal et
      _customers = []; // Müşteri listesini temizle
      if (_currentUserId != null) {
        fetchCustomers(_currentUserId!);
      } else {
        _isLoading = false; // Kullanıcı yoksa yüklemeyi durdur
        notifyListeners();
      }
    }
  }

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;

  void fetchCustomers(String userId) {
    if (userId.isEmpty) {
        print("CustomerProvider: Kullanıcı ID'si boş, müşteri çekilemiyor.");
        _customers = [];
        _isLoading = false;
        notifyListeners();
        return;
    }
    _isLoading = true;
    notifyListeners();

    _customersSubscription?.cancel();
    _customersSubscription = _firestoreService.getCustomers(userId).listen((customersData) {
      _customers = customersData;
      _isLoading = false;
      print("CustomerProvider: ${customersData.length} müşteri yüklendi (kullanıcı: $userId).");
      notifyListeners();
    }, onError: (error) {
      print("CustomerProvider Hata (kullanıcı: $userId): $error");
      _isLoading = false;
      _customers = [];
      notifyListeners();
    });
  }

  Future<bool> addCustomer(CustomerModel customer) async {
    if (_currentUserId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      // CustomerModel'in userId alanının doğru olduğundan emin olalım.
      final customerToAdd = CustomerModel(
        id: '', // Firestore kendi ID'sini atayacak
        userId: _currentUserId!,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        notes: customer.notes,
        createdAt: customer.createdAt ?? Timestamp.now(),
      );
      await _firestoreService.addCustomer(_currentUserId!, customerToAdd);
      // fetchCustomers stream'i dinlediği için liste otomatik güncellenecektir.
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    if (_currentUserId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updateCustomer(_currentUserId!, customer);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
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
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    _authProvider.removeListener(_authListener); // Dinleyiciyi kaldır
    super.dispose();
  }
}