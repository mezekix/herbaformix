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
      await _programRef(userId).set(program.toMap());

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
      return doc.exists && (doc.data()?['is_active'] == true);
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

      final routinesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('Daily_Routines');

      final snap = await routinesRef
          .where('scheduled_time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
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
    await _routineService.clearTodayRoutines(userId);

    final routinesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('Daily_Routines');

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
          final waterRef = routinesRef.doc();
          await waterRef.set(
            DailyRoutineModel(
              id: waterRef.id,
              productId: 'water_step',
              scheduledTime: waterTime,
              isCompleted: false,
              stepType: RoutineStepType.water,
              amountMl: 500,
            ).toMap(),
          );
        }

        // Normal öğün için label'ı "Dengeli bir X" formatında oluştur
        final mealLabel = _buildNormalMealLabel(slot.kind, slot.label);
        final mealRef = routinesRef.doc();
        await mealRef.set(
          DailyRoutineModel(
            id: mealRef.id,
            productId: mealLabel,
            scheduledTime: mealDateTime,
            isCompleted: false,
            stepType: RoutineStepType.normalMeal,
          ).toMap(),
        );
        continue;
      }

      // Su adımı: sadece ana öğünlerde (sabah, öğle, akşam) — ara öğünde yok
      if (slot.kind != MealSlotKind.snack) {
        final waterTime = mealDateTime.subtract(const Duration(minutes: 30));
        final waterRef = routinesRef.doc();
        await waterRef.set(
          DailyRoutineModel(
            id: waterRef.id,
            productId: 'water_step',
            scheduledTime: waterTime,
            isCompleted: false,
            stepType: RoutineStepType.water,
            amountMl: 500,
          ).toMap(),
        );
      }

      // Her ürün için ayrı rutin kaydı
      for (final mealProduct in slot.products) {
        final productRef = routinesRef.doc();
        await productRef.set(
          DailyRoutineModel(
            id: productRef.id,
            productId: mealProduct.productId,
            scheduledTime: mealDateTime,
            isCompleted: false,
            stepType: RoutineStepType.product,
          ).toMap(),
        );
      }
    }
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
        return 'Sağlıklı Ara Öğün';
    }
  }
}
