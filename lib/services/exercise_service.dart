import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Günlük egzersiz durumunu yöneten servis.
///
/// Firestore Yolu: /users/{userId}/daily_exercise/{yyyy-MM-dd}
/// Doküman Alanları:
///   - isCompleted (bool)
///   - updatedAt  (Timestamp)
class ExerciseService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Koleksiyon adı sabiti
  static const String _collectionName = 'daily_exercise';

  String? _userId;
  bool _todayCompleted = false;
  bool _isLoading = false;
  bool _isDisposed = false;
  StreamSubscription<DocumentSnapshot>? _subscription;

  // ── Getter'lar ──────────────────────────────────────────────────────────

  bool get todayCompleted => _todayCompleted;
  bool get isLoading => _isLoading;

  /// Egzersiz tamamlanma oranı: 0.0 veya 1.0
  double get progress => _todayCompleted ? 1.0 : 0.0;

  // ── Yaşam Döngüsü ─────────────────────────────────────────────────────

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  /// Kullanıcı giriş yaptığında çağrılır — bugünkü egzersiz dokümanını dinler.
  void startListening(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _isLoading = true;
    scheduleMicrotask(_safeNotify);

    _subscription?.cancel();
    _subscription = _firestore
        .collection('users')
        .doc(userId)
        .collection(_collectionName)
        .doc(_todayDocId)
        .snapshots()
        .listen(
      (snap) {
        _todayCompleted = snap.exists && (snap.data()?['isCompleted'] == true);
        _isLoading = false;
        _safeNotify();
      },
      onError: (e) {
        debugPrint('ExerciseService stream hatası: $e');
        _isLoading = false;
        _safeNotify();
      },
    );
  }

  /// Kullanıcı çıkış yaptığında çağrılır.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _userId = null;
    _todayCompleted = false;
    _isLoading = false;
    scheduleMicrotask(_safeNotify);
  }

  // ── Eylemler ───────────────────────────────────────────────────────────

  /// Bugünkü egzersiz durumunu günceller.
  Future<void> toggleExercise(bool completed) async {
    if (_userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection(_collectionName)
          .doc(_todayDocId)
          .set({
        'isCompleted': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Stream otomatik günceller, notifyListeners gerekmez
    } catch (e) {
      debugPrint('ExerciseService toggleExercise hatası: $e');
    }
  }

  // ── Yardımcılar ────────────────────────────────────────────────────────

  /// Bugünkü doküman ID'si: "2026-05-19" formatında
  String get _todayDocId {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
