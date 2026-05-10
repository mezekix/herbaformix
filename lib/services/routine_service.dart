import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_routine_model.dart';
import '../models/product_model.dart';

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
        .collection('Daily_Routines');
        
    final existingRoutines = await routinesRef
        .where('scheduled_time', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day)))
        .where('scheduled_time', isLessThan: Timestamp.fromDate(DateTime(now.year, now.month, now.day).add(const Duration(days: 1))))
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
        .collection('Daily_Routines');

    final todayDocs = await routinesRef
        .where(
          'scheduled_time',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(now.year, now.month, now.day),
          ),
        )
        .where(
          'scheduled_time',
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
        .collection('Daily_Routines');

    final allDocs = await routinesRef.get();
    for (var doc in allDocs.docs) {
      await doc.reference.delete();
    }
  }

  // Rutin durumunu güncelle (Tükettim checkbox için)
  Future<void> updateRoutineStatus(String userId, String routineId, bool isCompleted) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('Daily_Routines')
        .doc(routineId)
        .update({'is_completed': isCompleted});
  }

  // Rutin saatini güncelle
  Future<void> updateRoutineTime(String userId, String routineId, DateTime newTime) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('Daily_Routines')
        .doc(routineId)
        .update({'scheduled_time': Timestamp.fromDate(newTime)});
  }

  // Belirli bir tarihin rutinlerini getir
  Stream<List<DailyRoutineModel>> getDailyRoutines(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('Daily_Routines')
        .where('scheduled_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduled_time', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('scheduled_time')
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
        .collection('Daily_Routines');

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await routinesRef
          .where('scheduled_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduled_time', isLessThan: Timestamp.fromDate(endOfDay))
          .where('is_completed', isEqualTo: true)
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
}
