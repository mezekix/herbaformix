import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/water_log_model.dart';
import '../../../services/firestore_service.dart';

class WaterProvider with ChangeNotifier {
  final FirestoreService _firestoreService;

  static const int defaultGoal = 2500; // ml

  String? _userId;
  int _dailyGoal = defaultGoal;
  List<WaterLogModel> _todayLogs = [];
  bool _isLoading = false;
  StreamSubscription<List<WaterLogModel>>? _logsSubscription;
  bool _isDisposed = false;

  WaterProvider(this._firestoreService);

  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ── Getter'lar ────────────────────────────────────────────────────────────

  int get dailyGoal => _dailyGoal;
  List<WaterLogModel> get todayLogs => _todayLogs;
  bool get isLoading => _isLoading;

  int get totalConsumed =>
      _todayLogs.fold(0, (sum, log) => sum + log.amount);

  double get progress =>
      (totalConsumed / _dailyGoal).clamp(0.0, 1.0);

  // ── Kullanıcı bağlantısı ─────────────────────────────────────────────────

  /// Kullanıcı giriş yaptığında çağrılır — Firestore stream'ini başlatır.
  void startListening(String userId) {
    if (_userId == userId) return; // Aynı kullanıcı, tekrar başlatma
    _userId = userId;
    _isLoading = true;
    scheduleMicrotask(() => safeNotifyListeners());

    _logsSubscription?.cancel();
    _logsSubscription = _firestoreService
        .getWaterLogs(userId, DateTime.now())
        .listen(
          (logs) {
            _todayLogs = logs;
            _isLoading = false;
            safeNotifyListeners();
          },
          onError: (e) {
            debugPrint('WaterProvider stream hatası: $e');
            _isLoading = false;
            safeNotifyListeners();
          },
        );

    // Günlük hedefi yükle
    _loadGoal(userId);
  }

  /// Kullanıcı çıkış yaptığında çağrılır.
  void stopListening() {
    if (_userId == null) return;
    _logsSubscription?.cancel();
    _logsSubscription = null;
    _userId = null;
    _todayLogs = [];
    _dailyGoal = defaultGoal;
    _isLoading = false;
    scheduleMicrotask(() => safeNotifyListeners());
  }

  Future<void> _loadGoal(String userId) async {
    try {
      final goal = await _firestoreService.getWaterDailyGoal(userId);
      if (goal != null && goal > 0) {
        _dailyGoal = goal;
        safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('WaterProvider hedef yüklenirken hata: $e');
    }
  }

  // ── Eylemler ─────────────────────────────────────────────────────────────

  Future<void> addWater(int amount) async {
    if (_userId == null) return;
    final log = WaterLogModel(
      id: '',
      time: DateTime.now(),
      amount: amount,
    );
    try {
      await _firestoreService.addWaterLog(_userId!, log);
      // Stream otomatik günceller, notifyListeners gerekmez
    } catch (e) {
      debugPrint('WaterProvider addWater hatası: $e');
    }
  }

  /// Son logu siler.
  Future<void> removeLastLog() async {
    if (_userId == null || _todayLogs.isEmpty) return;
    final last = _todayLogs.last;
    try {
      await _firestoreService.deleteWaterLog(_userId!, last.id);
    } catch (e) {
      debugPrint('WaterProvider removeLastLog hatası: $e');
    }
  }

  /// Belirli bir logu ID'siyle siler.
  Future<void> removeLog(String logId) async {
    if (_userId == null) return;
    try {
      await _firestoreService.deleteWaterLog(_userId!, logId);
    } catch (e) {
      debugPrint('WaterProvider removeLog hatası: $e');
    }
  }

  /// Belirli miktarda suyu geri alır (en son logdan başlayarak).
  Future<void> removeWater(int amount) async {
    if (_userId == null) return;
    int remaining = amount;
    final toDelete = <String>[];

    for (int i = _todayLogs.length - 1; i >= 0 && remaining > 0; i--) {
      if (_todayLogs[i].amount <= remaining) {
        remaining -= _todayLogs[i].amount;
        toDelete.add(_todayLogs[i].id);
      } else {
        break; // Kısmi silme desteklenmiyor, dur
      }
    }

    for (final id in toDelete) {
      await _firestoreService.deleteWaterLog(_userId!, id);
    }
  }

  Future<void> setDailyGoal(int newGoal) async {
    if (_userId == null || newGoal <= 0) return;
    try {
      await _firestoreService.setWaterDailyGoal(_userId!, newGoal);
      _dailyGoal = newGoal;
      safeNotifyListeners();
    } catch (e) {
      debugPrint('WaterProvider setDailyGoal hatası: $e');
    }
  }

  /// Bugünkü tüm logları siler.
  Future<void> resetDailyProgress() async {
    if (_userId == null) return;
    try {
      await _firestoreService.clearWaterLogs(_userId!, DateTime.now());
    } catch (e) {
      debugPrint('WaterProvider resetDailyProgress hatası: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _logsSubscription?.cancel();
    super.dispose();
  }
}
