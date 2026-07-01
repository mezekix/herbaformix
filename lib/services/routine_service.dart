import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_routine_model.dart';
import '../models/product_model.dart';
import '../features/program/services/notification_service.dart';
import '../features/program/services/program_service.dart';
import '../features/program/models/program_model.dart';
import 'repositories/calorie_repository.dart';
import '../features/calorie_tracker/models/meal_model.dart';
import 'package:herbaformix/core/logger.dart';

class RoutineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Varsayılan offset aralığı (dakika) - ürünün Firestore'da offset'i yoksa kullanılır
  static const int _defaultOffsetIntervalMins = 30;

  // Akıllı Program Oluşturucu
  Future<void> generateDailyRoutine({
    required String userId,
    required String wakeTimeStr, // "07:30" formatında
    required List<ProductModel> assignedProducts,
  }) async {
    if (assignedProducts.isEmpty) return;

    final now = DateTime.now();
    // String'i saat ve dakikaya ayır
    final wakeTimeParts = wakeTimeStr.split(':');
    if (wakeTimeParts.length != 2) return;

    final wakeHour = int.parse(wakeTimeParts[0]);
    final wakeMinute = int.parse(wakeTimeParts[1]);

    // Uyanma saatini bugünün tarihiyle oluştur
    final baseWakeTime = DateTime(
      now.year,
      now.month,
      now.day,
      wakeHour,
      wakeMinute,
    );

    // Mevcut bugünkü rutinleri sil
    final routinesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines');
        
    final existingRoutines = await routinesRef
        .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day)))
        .where('scheduledTime', isLessThan: Timestamp.fromDate(DateTime(now.year, now.month, now.day).add(const Duration(days: 1))))
        .get();

    for (var doc in existingRoutines.docs) {
      await doc.reference.delete();
    }

    // Yeni rutinleri oluştur
    int fallbackIndex = 0;
    for (var product in assignedProducts) {
      // Ürünün Firestore'daki offset'ini kullan, yoksa sırayla 0, 30, 60, 90... dk ata
      final offsetMins = product.recommendedOffsetMins ?? (fallbackIndex * _defaultOffsetIntervalMins);
      final scheduledTime = baseWakeTime.add(Duration(minutes: offsetMins));
      
      final newRoutineRef = routinesRef.doc();
      final routine = DailyRoutineModel(
        id: newRoutineRef.id,
        productId: product.id,
        scheduledTime: scheduledTime,
        isCompleted: false,
      );

      await newRoutineRef.set(routine.toMap());
      fallbackIndex++;
    }
  }

  // Bugünkü rutinleri sil (program yenilenirken kullanılır)
  Future<void> clearTodayRoutines(String userId) async {
    final now = DateTime.now();
    final routinesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines');

    final todayDocs = await routinesRef
        .where(
          'scheduledTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(now.year, now.month, now.day),
          ),
        )
        .where(
          'scheduledTime',
          isLessThan: Timestamp.fromDate(
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
          ),
        )
        .get();

    for (var doc in todayDocs.docs) {
      await doc.reference.delete();
    }
  }

  // Kullanıcının tüm rutinlerini sil (Programı Sıfırla)
  Future<void> clearAllRoutines(String userId) async {
    final routinesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines');

    final allDocs = await routinesRef.get();
    for (var doc in allDocs.docs) {
      await doc.reference.delete();
    }
  }

  // Rutin durumunu güncelle (Tükettim checkbox için)
  Future<void> updateRoutineStatus(String userId, String routineId, bool isCompleted) async {
    // timeout: Firestore offline persistence sayesinde cache'e yazılır,
    // internet gelince otomatik senkronize edilir.
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines')
        .doc(routineId)
        .update({'isCompleted': isCompleted})
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            AppLogger.debug(
              '[RoutineService] updateRoutineStatus timeout — offline modda, cache\'e yazıldı.',
              tag: 'RoutineService',
            );
          },
        );

    try {
      // Önce cache'den oku, yoksa sunucudan dene
      DocumentSnapshot<Map<String, dynamic>> routineDoc;
      try {
        routineDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('dailyRoutines')
            .doc(routineId)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {
        routineDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('dailyRoutines')
            .doc(routineId)
            .get()
            .timeout(const Duration(seconds: 3), onTimeout: () async {
          return _firestore
              .collection('users')
              .doc(userId)
              .collection('dailyRoutines')
              .doc(routineId)
              .get(const GetOptions(source: Source.cache));
        });
      }

      if (!routineDoc.exists) return;
      final data = routineDoc.data()!;
      final productId = data['productId'] as String? ?? '';
      final stepType = data['stepType'] as String? ?? 'product';

      String nameToCheck = productId;
      if (stepType == 'product' || stepType == 'RoutineStepType.product') {
        // Önce cache'den ürün adını al
        try {
          final productDoc = await _firestore
              .collection('products')
              .doc(productId)
              .get(const GetOptions(source: Source.cache));
          if (productDoc.exists) {
            nameToCheck = productDoc.data()?['name'] as String? ?? productId;
          }
        } catch (_) {
          // Cache'de yoksa sunucudan kısa timeout ile dene
          try {
            final productDoc = await _firestore
                .collection('products')
                .doc(productId)
                .get()
                .timeout(const Duration(seconds: 3));
            if (productDoc.exists) {
              nameToCheck = productDoc.data()?['name'] as String? ?? productId;
            }
          } catch (_) {
            // Ürün adı alınamadı, productId ile devam et
          }
        }
      }

      final lower = nameToCheck.toLowerCase();
      final isShake = lower.contains('formül 1') ||
          lower.contains('formul 1') ||
          lower.contains('formula 1') ||
          lower.contains('formül1') ||
          lower.contains('formul1') ||
          lower.contains('formula1') ||
          lower.contains('shake') ||
          lower.contains('şek') ||
          lower.contains('mama') ||
          lower.contains('f1');

      if (isShake) {
        final calorieRepo = CalorieRepository(firestore: _firestore);
        if (isCompleted) {
          final meal = Meal(
            id: routineId,
            name: nameToCheck,
            calories: 250,
            timestamp: DateTime.now(),
          );
          await calorieRepo.addMealToday(userId, meal);
        } else {
          await calorieRepo.removeMealToday(userId, routineId);
        }
      }
    } catch (e) {
      AppLogger.error('[RoutineService] Auto-calorie error: $e',
          tag: 'RoutineService', error: e);
    }
  }


  // Rutin saatini güncelle
  Future<void> updateRoutineTime(String userId, String routineId, DateTime newTime) async {
    // 1. Mevcut rutini oku (slotId almak için)
    final routineDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines')
        .doc(routineId)
        .get();

    if (!routineDoc.exists) return;
    final routine = DailyRoutineModel.fromMap(routineDoc.data()!, routineDoc.id);

    // 2. dailyRoutines dokümanındaki scheduledTime'ı güncelle
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines')
        .doc(routineId)
        .update({'scheduledTime': Timestamp.fromDate(newTime)});

    // 3. Aktif programdaki slotun saatini güncelle (slotId yoksa eski saatle eşleştir)
    final programService = ProgramService();
    final program = await programService.getActiveProgram(userId);

    if (program != null) {
      final oldTimeStr = '${routine.scheduledTime.hour.toString().padLeft(2, '0')}:${routine.scheduledTime.minute.toString().padLeft(2, '0')}';
      final newTimeStr = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
      
      final updatedSlots = program.slots.map((s) {
        final isMatch = (routine.slotId != null && routine.slotId!.isNotEmpty && s.id == routine.slotId) || 
                        ((routine.slotId == null || routine.slotId!.isEmpty) && s.scheduledTime == oldTimeStr);
                        
        if (isMatch) {
          return s.copyWith(scheduledTime: newTimeStr);
        }
        return s;
      }).toList();

      final updatedProgram = program.copyWith(slots: updatedSlots);
      
      // Aktif programı Firestore'da güncelle
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('program')
          .doc('active')
          .set(updatedProgram.toMap());

      // 4. Eğer güncelleyen kullanıcı kendi programını güncelliyorsa local bildirimleri de yenile
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == userId) {
        await _rescheduleNotifications(updatedProgram);
      }
    }
  }

  // Bildirimleri yeniden zamanlama yardımcı fonksiyonu (ProgramProvider'dakine benzer)
  Future<void> _rescheduleNotifications(ProgramModel program) async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Önce tüm program bildirimlerini iptal et
    await notificationService.cancelAllProgramNotifications();

    for (final slot in program.slots) {
      final id = getMealNotificationId(slot.id);
      String title = '⏰ ${slot.label} Zamanı!';
      String body = 'Öğününüzü/Ürününüzü almayı unutmayın.';
      
      if (slot.products.isNotEmpty) {
        final productNames = slot.products.map((p) => p.productName).join(', ');
        title = '🥤 ${slot.label} Zamanı!';
        body = '$productNames kullanmayı unutmayın.';
      } else if (slot.isNormalMeal) {
        title = '🍽️ ${slot.label} Zamanı!';
        body = 'Sağlıklı bir öğün tüketmeyi unutmayın.';
      } else {
        title = '🍎 ${slot.label} Zamanı!';
        body = 'Ara öğün zamanı geldi, atıştırmalığınızı unutmayın.';
      }
      
      await notificationService.scheduleMealNotification(
        notificationId: id,
        title: title,
        body: body,
        scheduledTime: slot.scheduledTime,
        slotId: slot.id,
        isWater: false,
      );

      // Su bildirimi
      if (slot.kind != MealSlotKind.snack) {
        final timeParts = slot.scheduledTime.split(':');
        if (timeParts.length == 2) {
          final mealHour = int.tryParse(timeParts[0]) ?? 0;
          final mealMinute = int.tryParse(timeParts[1]) ?? 0;
          final now = DateTime.now();
          final mealTime = DateTime(now.year, now.month, now.day, mealHour, mealMinute);
          final waterTime = mealTime.subtract(const Duration(minutes: 30));
          
          final waterScheduledTime = '${waterTime.hour.toString().padLeft(2, '0')}:${waterTime.minute.toString().padLeft(2, '0')}';
          final waterId = id + 100000;
          
          await notificationService.scheduleMealNotification(
            notificationId: waterId,
            title: '💧 Su Hatırlatıcısı',
            body: '${slot.label} öncesinde 1 büyük bardak (500ml) su içmeyi unutmayın.',
            scheduledTime: waterScheduledTime,
            slotId: slot.id,
            isWater: true,
          );
        }
      }
    }
  }

  // Belirli bir tarihin rutinlerini getir
  Stream<List<DailyRoutineModel>> getDailyRoutines(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines')
        .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('scheduledTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyRoutineModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Son [days] günün her birinde en az bir tamamlanmış rutin olup olmadığını
  /// kontrol eder ve ardışık tamamlama serisini (streak) döndürür.
  /// Bugün dahil geriye doğru sayar; bir gün boşsa durur.
  Future<int> getCompletionStreak(String userId, {int days = 7}) async {
    final routinesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines');

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await routinesRef
          .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
          .where('isCompleted', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        streak++;
      } else {
        // Bugün (i==0) henüz tamamlanmamış olabilir, saymaya devam et
        if (i == 0) continue;
        break;
      }
    }

    return streak;
  }

  // Sadece bugün için tek seferlik bir rutin ekler
  Future<String> addSingleRoutine(String userId, DailyRoutineModel routine) async {
    final routinesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines');
        
    final newRef = routinesRef.doc();
    final newRoutine = routine.copyWith(id: newRef.id);
    await newRef.set(newRoutine.toMap());
    return newRef.id;
  }

  // Belirli bir rutini veritabanından siler (tek seferlik öğünleri veya o günkü rutini kaldırmak için)
  Future<void> deleteRoutine(String userId, String routineId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyRoutines')
        .doc(routineId)
        .delete();
  }
}
