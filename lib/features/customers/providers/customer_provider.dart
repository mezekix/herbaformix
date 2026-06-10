import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/customer_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

class CombinedCustomerEntry {
  final String id;
  final String name;
  final String phoneNumber;
  final String connectionType;
  final String? userProfileId;
  final CustomerModel? customerRecord;
  final bool isLinkedCustomer;

  const CombinedCustomerEntry({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.connectionType,
    this.userProfileId,
    this.customerRecord,
    this.isLinkedCustomer = false,
  });

  Timestamp? get activatedAt => customerRecord?.activatedAt;

  bool get isRecentlyActivated {
    final activated = activatedAt?.toDate();
    return activated != null &&
        DateTime.now().difference(activated).inDays < 7;
  }
}

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
  int get customersCount => _customers.length;

  List<CustomerModel> get recentlyActivatedCustomers {
    final now = DateTime.now();
    final list = _customers.where((customer) {
      final activated = customer.activatedAt?.toDate();
      return activated != null &&
          customer.linkedUserId != null &&
          now.difference(activated).inDays < 7;
    }).toList();
    list.sort(
      (a, b) => (b.activatedAt ?? Timestamp(0, 0))
          .compareTo(a.activatedAt ?? Timestamp(0, 0)),
    );
    return list;
  }

  // ───── Müşteri Pipeline segment'leri (Dashboard) ─────
  // Toplam = newCount + activeCount + passiveCount (overlap yok).
  // "Risk altı" Aktif'in alt kümesidir, insights servisinden ayrıca gelir.

  /// Son 7 gün içinde uygulamayı aktive eden müşteriler.
  int get newCustomersCount => recentlyActivatedCustomers.length;

  /// Uygulamayı kullanan, aktif olarak işaretlenmiş, "Yeni" olmayan müşteriler.
  int get activeCustomersCount {
    final newIds = recentlyActivatedCustomers.map((c) => c.id).toSet();
    return _customers
        .where((c) =>
            c.linkedUserId != null && c.isActive && !newIds.contains(c.id))
        .length;
  }

  /// Uygulamayı bağlamamış veya manuel olarak pasif işaretlenmiş müşteriler.
  int get passiveCustomersCount {
    return _customers
        .where((c) => c.linkedUserId == null || !c.isActive)
        .length;
  }

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
    _customersSubscription = _firestoreService.getCustomers(userId).listen(
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
        id: '',
        firstName: customer.firstName,
        lastName: customer.lastName,
        phoneNumber: customer.phoneNumber,
        email: customer.email,
        address: customer.address,
        firstContactDate: customer.firstContactDate,
        consultantId: _currentUserId!,
        isActive: customer.isActive,
        notes: customer.notes,
      );
      await _firestoreService.addCustomerWithInviteCode(
        distributorId: _currentUserId!,
        customer: customerToAdd,
      );
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

  Future<bool> deleteCombinedCustomer(CombinedCustomerEntry entry) async {
    if (_currentUserId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      if (entry.customerRecord != null) {
        await _firestoreService.deleteCustomer(_currentUserId!, entry.customerRecord!.id);
      } else if (entry.userProfileId != null) {
        await _firestoreService.disconnectDistributor(entry.userProfileId!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("CustomerProvider Hata (deleteCombinedCustomer): $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<CustomerModel?> getCustomerById(String customerId) async {
    if (_currentUserId == null) return null;

    try {
      return _customers.firstWhere(
        (c) => c.id == customerId || (c.linkedUserId != null && c.linkedUserId == customerId),
      );
    } catch (_) {}

    try {
      final doc = await _firestoreService.getCustomer(_currentUserId!, customerId);
      if (doc != null) return doc;
    } catch (_) {}

    try {
      final doc = await _firestoreService.getCustomerByLinkedUserId(_currentUserId!, customerId);
      if (doc != null) return doc;
    } catch (e) {
      debugPrint("CustomerProvider Hata (getCustomerById): $e");
    }

    return null;
  }

  Future<CustomerModel?> getLinkedCustomerFallback(
    CombinedCustomerEntry entry,
  ) async {
    if (_currentUserId == null) return null;

    if (entry.customerRecord != null) {
      return entry.customerRecord;
    }

    if (entry.userProfileId != null && entry.userProfileId!.isNotEmpty) {
      final linkedCustomer = await _firestoreService.getCustomerByLinkedUserId(
        _currentUserId!,
        entry.userProfileId!,
      );
      if (linkedCustomer != null) {
        return linkedCustomer;
      }

      final profile = await _firestoreService.getUserProfile(entry.userProfileId!);
      if (profile != null) {
        final createdCustomer =
            await _firestoreService.createCustomerRecordFromUserProfile(
          distributorId: _currentUserId!,
          profile: profile,
        );

        final existingIndex = _customers.indexWhere(
          (customer) => customer.id == createdCustomer.id,
        );
        if (existingIndex == -1) {
          _customers = [..._customers, createdCustomer];
        } else {
          _customers[existingIndex] = createdCustomer;
        }
        notifyListeners();
        return createdCustomer;
      }
    }

    final matchedByPhone = _customers.cast<CustomerModel?>().firstWhere(
          (customer) => customer != null && customer.phoneNumber == entry.phoneNumber,
          orElse: () => null,
        );

    return matchedByPhone;
  }

  Future<List<CombinedCustomerEntry>> getCombinedCustomers() async {
    if (_currentUserId == null) return [];

    try {
      final userProfileCustomers = await _firestoreService
          .fetchCustomersByDistributorId(_currentUserId!);
      final subCollectionCustomers =
          await _firestoreService.fetchAllCustomers(_currentUserId!);

      final result = <CombinedCustomerEntry>[];
      final addedIds = <String>{};
      final customerRecordsByLinkedUserId = <String, CustomerModel>{
        for (final customer in subCollectionCustomers)
          if (customer.linkedUserId != null && customer.linkedUserId!.isNotEmpty)
            customer.linkedUserId!: customer,
      };

      for (final profile in userProfileCustomers) {
        CustomerModel? customerRecord = customerRecordsByLinkedUserId[profile.id];
        customerRecord ??= await _firestoreService.getCustomerByLinkedUserId(
          _currentUserId!,
          profile.id,
        );
        result.add(
          CombinedCustomerEntry(
            id: profile.id,
            name: profile.name ?? '',
            phoneNumber: profile.phoneNumber ?? '',
            connectionType: 'davet_kodu',
            userProfileId: profile.id,
            customerRecord: customerRecord,
            isLinkedCustomer: true,
          ),
        );
        addedIds.add(profile.id);
      }

      for (final customer in subCollectionCustomers) {
        if (customer.linkedUserId == null ||
            !addedIds.contains(customer.linkedUserId)) {
          result.add(
            CombinedCustomerEntry(
              id: customer.id,
              name: '${customer.firstName} ${customer.lastName}'.trim(),
              phoneNumber: customer.phoneNumber,
              connectionType: 'manuel',
              userProfileId: customer.linkedUserId,
              customerRecord: customer,
              isLinkedCustomer: customer.linkedUserId != null,
            ),
          );
          if (customer.linkedUserId != null) {
            addedIds.add(customer.linkedUserId!);
          }
        }
      }

      return result;
    } catch (e) {
      debugPrint('CustomerProvider Hata (getCombinedCustomers): $e');
      return [];
    }
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    _authProvider.removeListener(_authListener);
    super.dispose();
  }
}