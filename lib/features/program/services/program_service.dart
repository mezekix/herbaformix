import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/daily_routine_model.dart';
import '../../../models/product_model.dart';
import '../../../services/routine_service.dart';
import '../models/program_model.dart';
/// Müşteri programı için Firestore CRUD işlemlerini yöneten servis.
/// Firestore yolu: users/{uid}/program (tek doküman, ID = 'active')
class ProgramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoutineService _routineService = RoutineService();

  static const String _programDocId = 'active';

  DocumentReference<Map<String, dynamic>> _programRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('program')
        .doc(_programDocId);
  }

  /// Programı Firestore'a kaydeder.
  /// Mevcut aktif program varsa önce siler.
  /// Kayıt sonrası günlük rutinleri ve su adımlarını oluşturur.
  Future<void> saveProgram(
    String userId,
    ProgramModel program,
    List<ProductModel> allProducts,
  ) async {
    try {
      // Mevcut bildirimleri iptal et (NotificationService dışarıdan çağrılır)
      // Önce eski programı sil
      await _programRef(userId).set(program.toMap()).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('[ProgramService] saveProgram set() timeout - offline modda olabilir, devam ediliyor.');
        },
      );

      // Günlük rutinleri oluştur
      await _generateRoutinesFromProgram(userId, program, allProducts);
    } on FirebaseException catch (e) {
      debugPrint('[ProgramService] saveProgram hatası: ${e.message}');
      rethrow;
    }
  }

  /// Aktif programı getirir. Yoksa null döner.
  Future<ProgramModel?> getActiveProgram(String userId) async {
    try {
      final doc = await _programRef(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ProgramModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[ProgramService] getActiveProgram hatası: ${e.message}');
      return null;
    }
  }

  /// Aktif programı gerçek zamanlı stream olarak döndürür.
  Stream<ProgramModel?> watchActiveProgram(String userId) {
    return _programRef(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProgramModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Programı siler ve tüm günlük rutinleri temizler.
  Future<void> deleteProgram(String userId) async {
    try {
      await _programRef(userId).delete();
      await _routineService.clearAllRoutines(userId);
    } on FirebaseException catch (e) {
      debugPrint('[ProgramService] deleteProgram hatası: ${e.message}');
      rethrow;
    }
  }

  /// Aktif program var mı kontrol eder.
  Future<bool> hasActiveProgram(String userId) async {
    try {
      final doc = await _programRef(userId).get();
      return doc.exists && (doc.data()?['isActive'] == true);
    } on FirebaseException catch (e) {
      debugPrint('[ProgramService] hasActiveProgram hatası: ${e.message}');
      return false;
    }
  }

  /// Günün rutinleri yoksa, aktif program üzerinden bugünün rutinlerini oluşturur.
  Future<void> ensureTodayRoutines(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final routinesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyRoutines');

      final snap = await routinesRef
          .where('scheduledTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledTime',
              isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        final program = await getActiveProgram(userId);
        if (program != null && program.isActive) {
          debugPrint('[ProgramService] Bugün için rutin bulunamadı, oluşturuluyor...');
          await _generateRoutinesFromProgram(userId, program, []);
        }
      }
    } catch (e) {
      debugPrint('[ProgramService] ensureTodayRoutines hatası: $e');
    }
  }

  /// Program öğün planından günlük rutinleri ve su adımlarını oluşturur.
  Future<void> _generateRoutinesFromProgram(
    String userId,
    ProgramModel program,
    List<ProductModel> allProducts,
  ) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final routinesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines');

    // Mevcut bugünkü rutinleri al ve tamamlama durumlarını (isCompleted) sakla
    final todayDocs = await routinesRef
        .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final completedMap = <String, bool>{};
    final batch = _firestore.batch(); // Atomik işlem için batch kullanıyoruz

    for (var doc in todayDocs.docs) {
      final data = doc.data();
      final pId = data['productId'] as String? ?? '';
      final time = (data['scheduledTime'] as Timestamp).toDate();
      final key = '${pId}_${time.hour}:${time.minute}';
      if (data['isCompleted'] == true) {
        completedMap[key] = true;
      }
      // Eski rutini silmek üzere batch'e ekle
      batch.delete(doc.reference);
    }

    // Slotları saate göre sırala
    final sortedSlots = program.sortedSlots;

    for (final slot in sortedSlots) {
      if (slot.products.isEmpty && !slot.isNormalMeal) continue;

      final timeParts = slot.scheduledTime.split(':');
      if (timeParts.length != 2) continue;
      final mealHour = int.tryParse(timeParts[0]) ?? 0;
      final mealMinute = int.tryParse(timeParts[1]) ?? 0;
      final mealDateTime = DateTime(
          now.year, now.month, now.day, mealHour, mealMinute);

      if (slot.isNormalMeal) {
        // Normal öğünde de su adımı ekle (snack hariç)
        if (slot.kind != MealSlotKind.snack) {
          final waterTime = mealDateTime.subtract(const Duration(minutes: 30));
          final waterKey = 'water_step_${waterTime.hour}:${waterTime.minute}';
          final waterRef = routinesRef.doc();
          batch.set(
            waterRef,
            DailyRoutineModel(
              id: waterRef.id,
              productId: 'water_step',
              scheduledTime: waterTime,
              isCompleted: completedMap[waterKey] ?? false,
              stepType: RoutineStepType.water,
              amountMl: 500,
              slotId: slot.id,
            ).toMap(),
          );
        }

        // Normal öğün için label'ı oluştur
        final mealLabel = _buildNormalMealLabel(slot.kind, slot.label);
        final mealKey = '${mealLabel}_${mealDateTime.hour}:${mealDateTime.minute}';
        final mealRef = routinesRef.doc();
        batch.set(
          mealRef,
          DailyRoutineModel(
            id: mealRef.id,
            productId: mealLabel,
            scheduledTime: mealDateTime,
            isCompleted: completedMap[mealKey] ?? false,
            stepType: RoutineStepType.normalMeal,
            slotId: slot.id,
          ).toMap(),
        );
        continue;
      }

      // Su adımı: sadece ana öğünlerde (sabah, öğle, akşam) — ara öğünde yok
      if (slot.kind != MealSlotKind.snack) {
        final waterTime = mealDateTime.subtract(const Duration(minutes: 30));
        final waterKey = 'water_step_${waterTime.hour}:${waterTime.minute}';
        final waterRef = routinesRef.doc();
        batch.set(
          waterRef,
          DailyRoutineModel(
            id: waterRef.id,
            productId: 'water_step',
            scheduledTime: waterTime,
            isCompleted: completedMap[waterKey] ?? false,
            stepType: RoutineStepType.water,
            amountMl: 500,
            slotId: slot.id,
          ).toMap(),
        );
      }

      // Her ürün için ayrı rutin kaydı
      for (final mealProduct in slot.products) {
        final pKey = '${mealProduct.productId}_${mealDateTime.hour}:${mealDateTime.minute}';
        final productRef = routinesRef.doc();
        batch.set(
          productRef,
          DailyRoutineModel(
            id: productRef.id,
            productId: mealProduct.productId,
            scheduledTime: mealDateTime,
            isCompleted: completedMap[pKey] ?? false,
            stepType: RoutineStepType.product,
            slotId: slot.id,
          ).toMap(),
        );
      }
    }

    // Tüm silme ve yazma işlemlerini tek seferde uygula
    await batch.commit().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        debugPrint('[ProgramService] _generateRoutinesFromProgram batch.commit() timeout - offline modda olabilir, devam ediliyor.');
      },
    );
  }

  /// Normal öğün için "Dengeli bir X" formatında label oluşturur
  String _buildNormalMealLabel(MealSlotKind kind, String fallbackLabel) {
    switch (kind) {
      case MealSlotKind.lunch:
        return 'Dengeli bir Öğlen Yemeği';
      case MealSlotKind.evening:
        return 'Dengeli bir Akşam Yemeği';
      case MealSlotKind.morning:
        return 'Dengeli bir Kahvaltı';
      case MealSlotKind.snack:
        return fallbackLabel.isNotEmpty ? fallbackLabel : 'Sağlıklı Ara Öğün';
    }
  }
}
