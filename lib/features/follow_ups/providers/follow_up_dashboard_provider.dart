import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/scheduled_follow_up_model.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:herbaformix/core/logger.dart';

/// Müşteri Takipleri dashboard'u için filtre seçenekleri.
enum FollowUpFilter { all, overdue, today, thisWeek, completed }

/// Tüm müşterilerin planlanmış takiplerini merkezi olarak yöneten Provider.
/// Müşteri Takipleri ekranı bu provider'ı kullanır.
class FollowUpDashboardProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthProvider _authProvider;

  String? _currentUserId;
  StreamSubscription<List<ScheduledFollowUpModel>>? _subscription;

  List<ScheduledFollowUpModel> _allFollowUps = [];
  FollowUpFilter _activeFilter = FollowUpFilter.all;
  String _searchQuery = '';
  String? _selectedCustomerId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FollowUpFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  String? get selectedCustomerId => _selectedCustomerId;

  FollowUpDashboardProvider(this._firestoreService, this._authProvider) {
    _currentUserId = _authProvider.firebaseUser?.uid;
    _authProvider.addListener(_authListener);
    if (_currentUserId != null) {
      _listenToAllFollowUps(_currentUserId!);
    }
  }

  void _authListener() {
    final newUserId = _authProvider.firebaseUser?.uid;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _subscription?.cancel();
      _allFollowUps = [];
      if (_currentUserId != null) {
        _listenToAllFollowUps(_currentUserId!);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _listenToAllFollowUps(String userId) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _firestoreService
        .getAllScheduledFollowUpsForConsultant(userId)
        .listen(
          (data) {
            _allFollowUps = data;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            AppLogger.error(
              'FollowUpDashboardProvider Hata: $error',
              tag: 'FollowUpDashboardProvider',
            );
            _isLoading = false;
            _allFollowUps = [];
            notifyListeners();
          },
        );
  }

  // ── Filtrelenmiş Listeler ─────────────────────────────────────────────

  /// Aktif filtreye, arama sorgusuna ve seçili müşteriye göre filtrelenmiş liste.
  List<ScheduledFollowUpModel> get filteredFollowUps {
    var list = _applyBaseFilter();
    list = _applyCustomerFilter(list);
    list = _applySearchQuery(list);
    return list;
  }

  List<ScheduledFollowUpModel> _applyBaseFilter() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final endOfWeek = startOfToday.add(const Duration(days: 7));

    switch (_activeFilter) {
      case FollowUpFilter.all:
        return _allFollowUps.where((f) => !f.isCompleted).toList();
      case FollowUpFilter.overdue:
        return _allFollowUps
            .where((f) => !f.isCompleted && f.dueDate.toDate().isBefore(startOfToday))
            .toList();
      case FollowUpFilter.today:
        return _allFollowUps.where((f) {
          if (f.isCompleted) return false;
          final d = f.dueDate.toDate();
          return !d.isBefore(startOfToday) && d.isBefore(endOfToday);
        }).toList();
      case FollowUpFilter.thisWeek:
        return _allFollowUps.where((f) {
          if (f.isCompleted) return false;
          final d = f.dueDate.toDate();
          return !d.isBefore(startOfToday) && d.isBefore(endOfWeek);
        }).toList();
      case FollowUpFilter.completed:
        return _allFollowUps.where((f) => f.isCompleted).toList();
    }
  }

  List<ScheduledFollowUpModel> _applyCustomerFilter(
    List<ScheduledFollowUpModel> list,
  ) {
    if (_selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
      return list;
    }
    return list.where((f) => f.customerId == _selectedCustomerId).toList();
  }

  List<ScheduledFollowUpModel> _applySearchQuery(
    List<ScheduledFollowUpModel> list,
  ) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((f) {
      return f.customerFullName.toLowerCase().contains(q) ||
          f.title.toLowerCase().contains(q) ||
          (f.notes?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ── Sayaçlar ──────────────────────────────────────────────────────────

  int get overdueCount {
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return _allFollowUps
        .where((f) => !f.isCompleted && f.dueDate.toDate().isBefore(now))
        .length;
  }

  int get todayCount {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _allFollowUps.where((f) {
      if (f.isCompleted) return false;
      final d = f.dueDate.toDate();
      return !d.isBefore(start) && d.isBefore(end);
    }).length;
  }

  int get thisWeekCount {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 7));
    return _allFollowUps.where((f) {
      if (f.isCompleted) return false;
      final d = f.dueDate.toDate();
      return !d.isBefore(start) && d.isBefore(end);
    }).length;
  }

  int get completedCount =>
      _allFollowUps.where((f) => f.isCompleted).length;

  int get pendingCount =>
      _allFollowUps.where((f) => !f.isCompleted).length;

  /// Benzersiz müşteri listesi (filtre dropdown için)
  List<({String id, String name})> get uniqueCustomers {
    final map = <String, String>{};
    for (final f in _allFollowUps) {
      if (!map.containsKey(f.customerId)) {
        map[f.customerId] = f.customerFullName;
      }
    }
    final entries = map.entries
        .map((e) => (id: e.key, name: e.value))
        .toList();
    entries.sort((a, b) => a.name.compareTo(b.name));
    return entries;
  }

  // ── Filtre ve Arama ───────────────────────────────────────────────────

  void setFilter(FollowUpFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCustomer(String? customerId) {
    _selectedCustomerId = customerId;
    notifyListeners();
  }

  void clearFilters() {
    _activeFilter = FollowUpFilter.all;
    _searchQuery = '';
    _selectedCustomerId = null;
    notifyListeners();
  }

  // ── CRUD İşlemleri ────────────────────────────────────────────────────

  /// Manuel yeni takip ekler.
  Future<bool> addManualFollowUp(ScheduledFollowUpModel followUp) async {
    if (_currentUserId == null) return false;
    try {
      await _firestoreService.addSingleScheduledFollowUp(followUp);
      return true;
    } catch (e) {
      AppLogger.error(
        'Manuel takip eklenemedi: $e',
        tag: 'FollowUpDashboardProvider',
        error: e,
      );
      return false;
    }
  }

  /// Belirli bir ürün ve müşteri için otomatik takip planı (1, 3, 7, 15, 30 gün) oluşturur.
  Future<bool> generateFollowUpPlan({
    required String customerId,
    required String customerFirstName,
    required String customerLastName,
    required String productName,
    DateTime? startDate,
  }) async {
    if (_currentUserId == null) return false;
    
    final baseDate = startDate ?? DateTime.now();
    final scheduleDays = [1, 3, 7, 15, 30];
    final List<ScheduledFollowUpModel> followUpBatch = [];

    for (var day in scheduleDays) {
      final followUpTitle = productName.isNotEmpty
          ? '$productName - $day. Gün Kontrolü'
          : '$day. Gün Kontrolü';
      followUpBatch.add(
        ScheduledFollowUpModel(
          id: '',
          consultantId: _currentUserId!,
          customerId: customerId,
          customerFirstName: customerFirstName,
          customerLastName: customerLastName,
          dueDate: Timestamp.fromDate(baseDate.add(Duration(days: day))),
          title: followUpTitle,
          isCompleted: false,
          isAutoGenerated: true,
          createdAt: Timestamp.now(),
        ),
      );
    }

    try {
      await _firestoreService.addScheduledFollowUpBatch(followUpBatch);
      return true;
    } catch (e) {
      AppLogger.error(
        'Otomatik takip planı oluşturulamadı: $e',
        tag: 'FollowUpDashboardProvider',
        error: e,
      );
      return false;
    }
  }

  /// Mevcut bir takibi günceller.
  Future<bool> updateFollowUp(ScheduledFollowUpModel followUp) async {
    if (_currentUserId == null) return false;
    try {
      await _firestoreService.updateScheduledFollowUp(followUp);
      return true;
    } catch (e) {
      AppLogger.error(
        'Takip güncellenemedi: $e',
        tag: 'FollowUpDashboardProvider',
        error: e,
      );
      return false;
    }
  }

  /// Bir takibi siler.
  Future<bool> deleteFollowUp(String followUpId) async {
    try {
      await _firestoreService.deleteScheduledFollowUp(followUpId);
      return true;
    } catch (e) {
      AppLogger.error(
        'Takip silinemedi: $e',
        tag: 'FollowUpDashboardProvider',
        error: e,
      );
      return false;
    }
  }

  /// Bir takibi tamamlandı olarak işaretler.
  Future<bool> completeFollowUp(String followUpId) async {
    try {
      await _firestoreService.markScheduledFollowUpAsCompleted(followUpId);
      return true;
    } catch (e) {
      AppLogger.error(
        'Takip tamamlanamadı: $e',
        tag: 'FollowUpDashboardProvider',
        error: e,
      );
      return false;
    }
  }

  /// Bir takibi belirtilen tarihe erteler.
  Future<bool> snoozeFollowUp(String followUpId, DateTime newDate) async {
    try {
      await _firestoreService.snoozeScheduledFollowUp(followUpId, newDate);
      return true;
    } catch (e) {
      AppLogger.error(
        'Takip ertelenemedi: $e',
        tag: 'FollowUpDashboardProvider',
        error: e,
      );
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authProvider.removeListener(_authListener);
    super.dispose();
  }
}
