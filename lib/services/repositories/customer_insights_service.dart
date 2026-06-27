import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/distributor_customer_insights.dart';
import '../../models/progress_entry_model.dart';
import 'progress_repository.dart';
import 'user_profile_repository.dart';
import 'package:herbaformix/core/logger.dart';

/// Distribütör panelinde müşteri kartlarını besleyen cross-domain özet servis.
///
/// Tek bir [getDistributorCustomerInsights] çağrısı birden çok koleksiyondan
/// (progressEntries, waterLogs, dailyRoutines, userProfiles) paralel okumalar
/// yapar. Bu yüzden repository değil "service" olarak konumlandırılmıştır —
/// kompozit okuma.
class CustomerInsightsService {
  CustomerInsightsService({
    FirebaseFirestore? firestore,
    ProgressRepository? progressRepo,
    UserProfileRepository? userProfileRepo,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _progressRepo = progressRepo ?? ProgressRepository(firestore: firestore),
        _userProfileRepo =
            userProfileRepo ?? UserProfileRepository(firestore: firestore);

  final FirebaseFirestore _db;
  final ProgressRepository _progressRepo;
  final UserProfileRepository _userProfileRepo;

  Future<DistributorCustomerInsights> getDistributorCustomerInsights(
    String customerUserId,
  ) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));
      final sevenDaysAgo = startOfToday.subtract(const Duration(days: 6));

      final latestProgressFuture = _progressRepo
          .ref(customerUserId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      final allProgressFuture = _progressRepo
          .ref(customerUserId)
          .orderBy('date', descending: false)
          .get();
      final todayWaterFuture = _db
          .collection('users')
          .doc(customerUserId)
          .collection('waterLogs')
          .where('time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('time', isLessThan: Timestamp.fromDate(endOfToday))
          .get();
      final recentRoutinesFuture = _db
          .collection('users')
          .doc(customerUserId)
          .collection('dailyRoutines')
          .where('scheduledTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfToday))
          .get();
      final userProfileFuture =
          _userProfileRepo.getUserProfile(customerUserId);

      final results = await Future.wait([
        latestProgressFuture,
        allProgressFuture,
        todayWaterFuture,
        recentRoutinesFuture,
        userProfileFuture,
      ]);

      final latestProgressSnap =
          results[0] as QuerySnapshot<ProgressEntryModel>;
      final allProgressSnap = results[1] as QuerySnapshot<ProgressEntryModel>;
      final todayWaterSnap =
          results[2] as QuerySnapshot<Map<String, dynamic>>;
      final recentRoutinesSnap =
          results[3] as QuerySnapshot<Map<String, dynamic>>;
      final userProfile = results[4] as dynamic;

      final latestProgress = latestProgressSnap.docs.isNotEmpty
          ? latestProgressSnap.docs.first.data()
          : null;

      final todayWaterMl = todayWaterSnap.docs.fold<int>(
        0,
        (total, doc) => total + ((doc.data()['amount'] as num?)?.toInt() ?? 0),
      );

      final routines = recentRoutinesSnap.docs.map((d) => d.data()).toList();
      final completedRoutines =
          routines.where((r) => r['isCompleted'] == true);

      DateTime? latestRoutineAt;
      if (recentRoutinesSnap.docs.isNotEmpty) {
        latestRoutineAt = recentRoutinesSnap.docs
            .map((d) => (d.data()['scheduledTime'] as Timestamp).toDate())
            .fold<DateTime?>(
                null,
                (latest, current) =>
                    latest == null || current.isAfter(latest)
                        ? current
                        : latest);
      }

      // Riskli müşteri tespiti için: son **tamamlanmış** rutinin zamanı.
      // (latestRoutineAt scheduled time'a bakar; risk için "yapıldı mı"
      //  sorusunun cevabı lazım.)
      DateTime? latestCompletedRoutineAt;
      final completedDocs = recentRoutinesSnap.docs
          .where((d) => d.data()['isCompleted'] == true);
      if (completedDocs.isNotEmpty) {
        latestCompletedRoutineAt = completedDocs
            .map((d) => (d.data()['scheduledTime'] as Timestamp).toDate())
            .fold<DateTime?>(
                null,
                (latest, current) =>
                    latest == null || current.isAfter(latest)
                        ? current
                        : latest);
      }

      DateTime? latestWaterAt;
      if (todayWaterSnap.docs.isNotEmpty) {
        latestWaterAt = todayWaterSnap.docs
            .map((d) => (d.data()['time'] as Timestamp).toDate())
            .fold<DateTime?>(
                null,
                (latest, current) =>
                    latest == null || current.isAfter(latest)
                        ? current
                        : latest);
      }

      final lastActivityCandidates = [
        latestProgress?.date,
        latestRoutineAt,
        latestWaterAt,
      ].whereType<DateTime>().toList()
        ..sort((a, b) => b.compareTo(a));

      // Son 90 günlük progress entries
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final progressEntries = allProgressSnap.docs
          .map((d) => d.data())
          .where((e) => e.date.isAfter(cutoff))
          .toList();

      return DistributorCustomerInsights(
        latestProgress: latestProgress,
        progressEntries: progressEntries,
        todayWaterMl: todayWaterMl,
        waterGoalMl: userProfile?.waterDailyGoal ?? 2000,
        completedRoutinesLast7Days: completedRoutines.length,
        totalRoutinesLast7Days: routines.length,
        lastActivityAt: lastActivityCandidates.isEmpty
            ? null
            : lastActivityCandidates.first,
        lastCompletedRoutineAt: latestCompletedRoutineAt,
        programStartDate: userProfile?.programStartDate,
      );
    } catch (e) {
      AppLogger.error('getDistributorCustomerInsights hatası: $e', tag: 'CustomerInsightsService', error: e);
      return const DistributorCustomerInsights(
        latestProgress: null,
        todayWaterMl: 0,
        waterGoalMl: 2000,
        completedRoutinesLast7Days: 0,
        totalRoutinesLast7Days: 0,
        lastActivityAt: null,
      );
    }
  }

  /// Distribütörün atanmış müşterileri arasında "risk altında" olanların
  /// sayısı. ⚠️ O(N) okuma — her müşteri için 5 paralel sorgu. Büyük
  /// portföylerde cache veya Cloud Function ile yer değiştirilmeli (PRD-P3).
  Future<int> getAtRiskCustomerCount(String distributorId) async {
    try {
      final customers =
          await _userProfileRepo.getCustomersByDistributorId(distributorId).first;
      if (customers.isEmpty) return 0;
      final insights = await Future.wait(
        customers.map((c) => getDistributorCustomerInsights(c.id)),
      );
      return insights.where((i) => i.isAtRisk).length;
    } catch (e) {
      AppLogger.error('getAtRiskCustomerCount hatası: $e', tag: 'CustomerInsightsService', error: e);
      return 0;
    }
  }
}
