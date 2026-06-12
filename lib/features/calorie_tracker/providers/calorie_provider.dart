import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/calorie_calculation_engine.dart';
import '../../../models/user_profile_model.dart';
import '../../../services/repositories/calorie_repository.dart';
import '../models/calorie_daily_log.dart';
import '../models/meal_model.dart';

/// Bugünkü kalori durumunu Firestore'dan dinleyen ve geçmişi sorgulayan provider.
///
/// **Otomatik hedef**: Yeni gün log'u veya kullanıcının "otomatik" seçtiği
/// günler için, Mifflin-St Jeor BMR + TDEE + userGoal offset'i hesaplanır.
///
/// Provider artık AuthProvider/WaterProvider'a listener bağlamaz — bu tree
/// cycle'a yol açıyordu. Onun yerine UI bu provider'ı `Consumer3` ile
/// dinleyip, post-frame'de [recomputeIfAuto] / [computeGoalPreview] çağırır
/// ve gerekli profil + aktivite parametrelerini dışarıdan verir.
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

  // Reentrancy ve sync koruması — otomatik recompute aynı değer için
  // gereksiz Firestore yazması yapmasın.
  bool _isRecomputing = false;
  int? _lastWrittenAutoGoal;

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

  /// Bugünün hedefinin otomatik mi manuel mi olduğunu döner.
  bool get isAutoGoal => _todayLog?.isAutoGoal ?? false;

  /// UI'nın anlık önizleme için: verilen profil + aktivite seviyesinden
  /// hesaplanan kalori sonucunu döner. Profil yoksa null.
  CalorieGoalResult? computeGoalPreview({
    required UserProfileModel? profile,
    required String exerciseLevel,
  }) {
    if (profile == null) return null;
    return CalorieCalculationEngine.calculateGoal(
      profile: profile,
      exerciseLevel: exerciseLevel,
    );
  }

  /// Otomatik hesaplama için profilde eksik olan alanların Türkçe isimleri.
  /// Liste boşsa profil tamam; UI banner göstermez.
  List<String> missingProfileFields(UserProfileModel? profile) =>
      CalorieCalculationEngine.missingFieldsFor(profile);

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
    _lastWrittenAutoGoal = null;
    notifyListeners();
  }

  // ── Otomatik hedef recompute ──────────────────────────────────────────────

  /// Bugünün log'u **otomatik** moddaysa, verilen profil + aktivite
  /// seviyesinden hesaplanmış hedefi Firestore'a yazar. Manuel moddaysa
  /// dokunmaz. Aynı değer son yazılandan farklı değilse Firestore'a
  /// yazmaz — gereksiz roundtrip'i önler.
  ///
  /// UI tarafı her Consumer build'inde (post-frame) çağırır.
  Future<void> recomputeIfAuto({
    required UserProfileModel? profile,
    required String exerciseLevel,
  }) async {
    if (_isRecomputing) return;
    final uid = _userId;
    final log = _todayLog;
    if (uid == null || log == null || profile == null) return;
    if (!log.isAutoGoal) return;

    final result = CalorieCalculationEngine.calculateGoal(
      profile: profile,
      exerciseLevel: exerciseLevel,
    );
    if (!result.isComplete) return;
    if (result.totalKcal == log.dailyGoal) return;
    if (result.totalKcal == _lastWrittenAutoGoal) return;

    _isRecomputing = true;
    _lastWrittenAutoGoal = result.totalKcal;
    try {
      await _repo.setTodayGoal(
        uid,
        result.totalKcal,
        defaultGoalFallback: calorieGoal,
        isAuto: true,
      );
    } catch (e) {
      debugPrint('[CalorieProvider] recomputeIfAuto: $e');
    } finally {
      _isRecomputing = false;
    }
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

  /// Kullanıcı manuel bir hedef girdi → isAutoGoal=false olarak yazar.
  /// Otomatik recompute bu değeri ezmeyi denemez.
  Future<void> setManualGoal(int newGoal) async {
    final uid = _userId;
    if (uid == null || newGoal <= 0) return;
    _lastWrittenAutoGoal = null; // auto recompute'u yeniden tetikleyebilsin
    try {
      await _repo.setTodayGoal(
        uid,
        newGoal,
        defaultGoalFallback: calorieGoal,
        isAuto: false,
      );
    } catch (e) {
      debugPrint('[CalorieProvider] setManualGoal: $e');
      _errorMessage = 'Hedef güncellenemedi: $e';
      notifyListeners();
    }
  }

  /// Kullanıcı "otomatik" moda geçti → profil + aktivite seviyesinden anlık
  /// hesapla, isAutoGoal=true olarak yaz. Profil eksikse hedef değişmez ve
  /// `false` döner.
  Future<bool> switchToAutoGoal({
    required UserProfileModel? profile,
    required String exerciseLevel,
  }) async {
    final uid = _userId;
    if (uid == null || profile == null) return false;
    final result = CalorieCalculationEngine.calculateGoal(
      profile: profile,
      exerciseLevel: exerciseLevel,
    );
    if (!result.isComplete) return false;
    _lastWrittenAutoGoal = result.totalKcal;
    try {
      await _repo.setTodayGoal(
        uid,
        result.totalKcal,
        defaultGoalFallback: calorieGoal,
        isAuto: true,
      );
      return true;
    } catch (e) {
      debugPrint('[CalorieProvider] switchToAutoGoal: $e');
      _errorMessage = 'Hedef güncellenemedi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Geriye uyumluluk — eski çağrıcılar setCalorieGoal'a manuel olarak girilmiş
  /// gibi davranır.
  @Deprecated('Use setManualGoal() or switchToAutoGoal() instead.')
  Future<void> setCalorieGoal(int newGoal) => setManualGoal(newGoal);

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
