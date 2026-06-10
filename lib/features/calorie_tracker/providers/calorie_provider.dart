import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../services/repositories/calorie_repository.dart';
import '../models/calorie_daily_log.dart';
import '../models/meal_model.dart';

/// Bugünkü kalori durumunu Firestore'dan dinleyen ve geçmişi sorgulayan provider.
///
/// `WaterProvider` pattern'iyle hizalanmış: auth-aware,
/// `startListening(uid)`/`stopListening()` ile yönetilir. Çıkışta cache
/// temizlenir, yeni kullanıcı girince yeni stream başlar.
///
/// Eski SharedPreferences tabanlı sürüm Bilinen Hatalar #1 nedeniyle terk
/// edildi — cihaz bağımlı, geçmiş yok.
class CalorieProvider with ChangeNotifier {
  CalorieProvider({CalorieRepository? repository})
      : _repo = repository ?? CalorieRepository();

  final CalorieRepository _repo;
  final Uuid _uuid = const Uuid();

  String? _userId;
  StreamSubscription<CalorieDailyLog?>? _todaySub;

  CalorieDailyLog? _todayLog;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Eski API yüzeyini koru ────────────────────────────────────────────────

  /// Mevcut günün hedef kalorisi. Henüz log yüklenmemişse 2000 fallback.
  int get calorieGoal => _todayLog?.dailyGoal ?? 2000;

  /// Bugünün toplam kalorisi.
  int get totalCalories => _todayLog?.totalCalories ?? 0;

  /// Bugünün öğünleri (yenisi üstte, repository'de zaten sıralı yazılıyor).
  List<Meal> get meals => _todayLog?.meals ?? const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Hedef tutturma oranı (0..1+).
  double get progress => _todayLog?.progress ?? 0.0;

  // ── Yaşam döngüsü ─────────────────────────────────────────────────────────

  /// Belirtilen kullanıcı için bugünün stream'ini başlatır.
  /// Aynı kullanıcı için tekrar çağrılırsa idempotent.
  void startListening(String userId) {
    if (_userId == userId && _todaySub != null) return;

    _userId = userId;
    _todaySub?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // İlk gün log'u yoksa kısa bir async tetik — gözlemleyici null görmesin.
    unawaited(_repo.ensureTodayLog(userId).catchError((Object e) {
      debugPrint('[CalorieProvider] ensureTodayLog: $e');
      return CalorieDailyLog.empty(date: DateTime.now());
    }));

    _todaySub = _repo.watchDay(userId, DateTime.now()).listen((log) {
      _todayLog = log;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('[CalorieProvider] watchDay error: $e');
      _errorMessage = 'Kalori verileri yüklenemedi: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Stream'leri iptal eder, cache'i temizler. Logout sonrası çağrılır.
  void stopListening() {
    _todaySub?.cancel();
    _todaySub = null;
    _userId = null;
    _todayLog = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Aksiyonlar ────────────────────────────────────────────────────────────

  Future<void> addMeal(String name, int calories) async {
    final uid = _userId;
    if (uid == null || name.trim().isEmpty || calories <= 0) return;
    final meal = Meal(
      id: _uuid.v4(),
      name: name.trim(),
      calories: calories,
      timestamp: DateTime.now(),
    );
    try {
      await _repo.addMealToday(uid, meal, defaultGoal: calorieGoal);
    } catch (e) {
      debugPrint('[CalorieProvider] addMeal: $e');
      _errorMessage = 'Öğün eklenemedi: $e';
      notifyListeners();
    }
  }

  Future<void> removeMeal(String mealId) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _repo.removeMealToday(uid, mealId);
    } catch (e) {
      debugPrint('[CalorieProvider] removeMeal: $e');
      _errorMessage = 'Öğün silinemedi: $e';
      notifyListeners();
    }
  }

  Future<void> setCalorieGoal(int newGoal) async {
    final uid = _userId;
    if (uid == null || newGoal <= 0) return;
    try {
      await _repo.setTodayGoal(uid, newGoal,
          defaultGoalFallback: calorieGoal);
    } catch (e) {
      debugPrint('[CalorieProvider] setCalorieGoal: $e');
      _errorMessage = 'Hedef güncellenemedi: $e';
      notifyListeners();
    }
  }

  // ── Geçmiş ────────────────────────────────────────────────────────────────

  /// Son [days] günün log listesini (en yeni üstte) stream eder.
  Stream<List<CalorieDailyLog>> watchRecent({int days = 30}) {
    final uid = _userId;
    if (uid == null) return Stream.value(const []);
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    return _repo.watchRange(uid, start, end).map(
          (list) => list.reversed.toList(),
        );
  }

  @override
  void dispose() {
    _todaySub?.cancel();
    super.dispose();
  }
}
