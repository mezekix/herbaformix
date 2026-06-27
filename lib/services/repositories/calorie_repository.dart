import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/calorie_tracker/models/calorie_daily_log.dart';
import '../../features/calorie_tracker/models/meal_model.dart';
import 'package:herbaformix/core/logger.dart';

/// `/users/{uid}/calorieLogs/{YYYY-MM-DD}` — günlük kalori kayıtları.
///
/// Her gün için tek bir doküman tutulur; öğünler embedded liste olarak
/// saklanır. Eski Faz 5.2 mimarisinde SharedPreferences kullanılıyordu —
/// veri kaybı yaşanıyordu (Bilinen Hatalar #1). Bu repository onu kapatır.
class CalorieRepository {
  CalorieRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _ref(String userId) =>
      _db.collection('users').doc(userId).collection('calorieLogs');

  /// Belirtilen günün log'unu gerçek zamanlı dinler. Yoksa null döner.
  Stream<CalorieDailyLog?> watchDay(String userId, DateTime date) {
    return _ref(userId)
        .doc(CalorieDailyLog.dateKey(date))
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CalorieDailyLog.fromMap(doc.data()!, doc.id);
    });
  }

  Future<CalorieDailyLog?> getDay(String userId, DateTime date) async {
    try {
      final doc =
          await _ref(userId).doc(CalorieDailyLog.dateKey(date)).get();
      if (!doc.exists || doc.data() == null) return null;
      return CalorieDailyLog.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      AppLogger.error('[CalorieRepository] getDay hatası: ${e.message}', tag: 'CalorieRepository', error: e);
      return null;
    }
  }

  /// [start] ve [end] arasındaki tüm günlük log'ları stream eder
  /// (eski tarih → yeni tarih sırasıyla).
  Stream<List<CalorieDailyLog>> watchRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    final startKey = CalorieDailyLog.dateKey(start);
    final endKey = CalorieDailyLog.dateKey(end);
    return _ref(userId)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CalorieDailyLog.fromMap(d.data(), d.id))
            .toList());
  }

  /// Bugünün log'u yoksa varsayılan hedefle oluşturur. Varsa dokunmaz.
  /// Yeni log'un goal'ı en son var olan log'dan veya verilen [defaultGoal]'dan
  /// alınır.
  Future<CalorieDailyLog> ensureTodayLog(
    String userId, {
    int defaultGoal = 2000,
  }) async {
    final today = DateTime.now();
    final existing = await getDay(userId, today);
    if (existing != null) return existing;

    // Önceki günün dailyGoal'ını kullanarak yeni gün için akıllı default.
    final lastGoal = await _findMostRecentGoal(userId) ?? defaultGoal;
    final fresh = CalorieDailyLog.empty(date: today, dailyGoal: lastGoal);
    await _ref(userId).doc(fresh.date).set(fresh.toMap());
    return fresh;
  }

  Future<int?> _findMostRecentGoal(String userId) async {
    try {
      final snap = await _ref(userId)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      return data['dailyGoal'] as int?;
    } on FirebaseException catch (e) {
      AppLogger.error('[CalorieRepository] _findMostRecentGoal: ${e.message}', tag: 'CalorieRepository', error: e);
      return null;
    }
  }

  /// Bugünün log'una yeni öğün ekler. totalCalories denormalize edilir.
  Future<void> addMealToday(
    String userId,
    Meal meal, {
    int defaultGoal = 2000,
  }) async {
    final today = await ensureTodayLog(userId, defaultGoal: defaultGoal);
    final updated = today.copyWith(
      meals: [...today.meals, meal]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      updatedAt: DateTime.now(),
    );
    await _ref(userId).doc(updated.date).set(updated.toMap());
  }

  /// Bugünün log'undan öğün siler.
  Future<void> removeMealToday(String userId, String mealId) async {
    final today = await getDay(userId, DateTime.now());
    if (today == null) return;
    final updated = today.copyWith(
      meals: today.meals.where((m) => m.id != mealId).toList(),
      updatedAt: DateTime.now(),
    );
    await _ref(userId).doc(updated.date).set(updated.toMap());
  }

  /// Bugünün hedefini değiştirir. Geçmiş günler etkilenmez.
  ///
  /// [isAuto] `true` ise hedef otomatik hesaplamadan geldi demektir — provider
  /// daha sonra (profil ya da aktivite değişince) bunu tekrar ezebilir.
  /// `false` ise kullanıcı manuel girdi — otomatik recompute saygı duyup
  /// dokunmaz.
  Future<void> setTodayGoal(
    String userId,
    int newGoal, {
    int defaultGoalFallback = 2000,
    bool isAuto = false,
  }) async {
    if (newGoal <= 0) return;
    final today =
        await ensureTodayLog(userId, defaultGoal: defaultGoalFallback);
    final updated = today.copyWith(
      dailyGoal: newGoal,
      isAutoGoal: isAuto,
      updatedAt: DateTime.now(),
    );
    await _ref(userId).doc(updated.date).set(updated.toMap());
  }
}
