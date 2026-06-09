import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/water_log_model.dart';
import '../../models/water_summary_model.dart';

/// `/users/{uid}/waterLogs/{logId}` ve `/users/{uid}/waterSummaries/{date}` —
/// su tüketim kayıtları ve günlük özetler.
class WaterRepository {
  WaterRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _logsRef(String userId) =>
      _db.collection('users').doc(userId).collection('waterLogs');

  CollectionReference<Map<String, dynamic>> _summariesRef(String userId) =>
      _db.collection('users').doc(userId).collection('waterSummaries');

  // ── logs ────────────────────────────────────────────────────────────────

  Stream<List<WaterLogModel>> getWaterLogs(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _logsRef(userId)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('time', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => WaterLogModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> addWaterLog(String userId, WaterLogModel log) async {
    await _logsRef(userId).add(log.toMap());
  }

  Future<void> deleteWaterLog(String userId, String logId) async {
    await _logsRef(userId).doc(logId).delete();
  }

  Future<void> updateWaterLog(String userId, WaterLogModel log) async {
    await _logsRef(userId).doc(log.id).update(log.toMap());
  }

  Future<void> clearWaterLogs(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snapshot = await _logsRef(userId)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── summaries ───────────────────────────────────────────────────────────

  Future<WaterSummaryModel?> getWaterSummary(
    String userId,
    String dateStr,
  ) async {
    try {
      final doc = await _summariesRef(userId).doc(dateStr).get();
      if (doc.exists && doc.data() != null) {
        return WaterSummaryModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('getWaterSummary hatası: $e');
      return null;
    }
  }

  Stream<WaterSummaryModel?> watchWaterSummary(String userId, String dateStr) {
    return _summariesRef(userId).doc(dateStr).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return WaterSummaryModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> setWaterSummary(
    String userId,
    WaterSummaryModel summary,
  ) async {
    try {
      await _summariesRef(userId).doc(summary.id).set(summary.toMap());
    } catch (e) {
      debugPrint('setWaterSummary hatası: $e');
    }
  }
}
