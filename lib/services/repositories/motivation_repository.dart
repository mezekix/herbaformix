import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:herbaformix/core/logger.dart';

/// `/motivations/{customerId}/daily_messages` ve `/motivation_scores/{docId}` —
/// distribütör motivasyon mesajları + müşteri günlük motivasyon skorları.
class MotivationRepository {
  MotivationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// O güne ait distribütör mesajını (varsa) getirir.
  Future<String?> getDistributorMotivationMessage(String customerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final s = await _db
          .collection('motivations')
          .doc(customerId)
          .collection('daily_messages')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (s.docs.isEmpty) return null;
      return s.docs.first.data()['distributor_mesaji'] as String?;
    } catch (e) {
      AppLogger.error('getDistributorMotivationMessage hatası: $e', tag: 'MotivationRepository', error: e);
      return null;
    }
  }

  /// O günün distribütör mesajını kaydeder (ID = 'today', upsert).
  Future<void> saveDistributorMotivationMessage(
    String customerId,
    String message,
  ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      await _db
          .collection('motivations')
          .doc(customerId)
          .collection('daily_messages')
          .doc('today')
          .set({
        'distributor_mesaji': message,
        'distributor_mesaji_tarihi': Timestamp.fromDate(startOfDay),
        // Get tarafının where('timestamp', ...) sorgusuyla uyumlu alan.
        'timestamp': Timestamp.fromDate(startOfDay),
        'sistem_soz_index': now.millisecondsSinceEpoch ~/ 86400000 % 100,
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('saveDistributorMotivationMessage hatası: $e', tag: 'MotivationRepository', error: e);
    }
  }

  /// Bugünün motivasyon skorunu (1-10) kaydeder.
  Future<void> saveMotivationScore(String customerId, int score) async {
    try {
      final now = DateTime.now();
      final docId = '${customerId}_${now.year}_${now.month}_${now.day}';

      await _db.collection('motivation_scores').doc(docId).set({
        'skor': score,
        'tarih': Timestamp.now(),
        'musteri_id': customerId,
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('saveMotivationScore hatası: $e', tag: 'MotivationRepository', error: e);
    }
  }

  /// Son [days] günün motivasyon skorlarını döner (en yeniden eskiye).
  Future<List<int>> getMotivationScoresLastDays(
    String customerId,
    int days,
  ) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1));
      final endDate = now.add(const Duration(days: 1));

      final s = await _db
          .collection('motivation_scores')
          .where('musteri_id', isEqualTo: customerId)
          .where('tarih',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('tarih', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('tarih', descending: true)
          .get();

      return s.docs
          .map((d) => (d.data()['skor'] as num?)?.toInt() ?? 0)
          .toList();
    } catch (e) {
      AppLogger.error('getMotivationScoresLastDays hatası: $e', tag: 'MotivationRepository', error: e);
      return const [];
    }
  }
}
