import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/badge_model.dart';
import '../../../models/progress_entry_model.dart';
import '../../../models/user_profile_model.dart';
import '../../../services/firestore_service.dart';

class ProgressProvider with ChangeNotifier {
  final FirestoreService _firestoreService;

  List<ProgressEntryModel> _entries = [];
  List<String> _earnedBadgeIds = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ProgressEntryModel>>? _entriesSubscription;

  ProgressProvider(this._firestoreService);

  List<ProgressEntryModel> get entries => _entries;
  List<String> get earnedBadgeIds => _earnedBadgeIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Kazanılan rozet tanımlarını döner.
  List<BadgeDefinition> get earnedBadges =>
      _earnedBadgeIds
          .map((id) => AppBadges.findById(id))
          .whereType<BadgeDefinition>()
          .toList();

  /// Henüz kazanılmamış rozet tanımlarını döner.
  List<BadgeDefinition> get unearnedBadges => AppBadges.all
      .where((b) => !_earnedBadgeIds.contains(b.id))
      .toList();

  // ── Özet hesaplamalar ──────────────────────────────────────────────────────

  /// Başlangıç kilosuna göre toplam kilo değişimi (negatif = kayıp).
  double get totalWeightChange {
    if (_entries.length < 2) return 0;
    return _entries.last.weight - _entries.first.weight;
  }

  /// Son kaydedilen kilo.
  double? get latestWeight =>
      _entries.isNotEmpty ? _entries.last.weight : null;

  /// Son kaydedilen bel ölçümü.
  double? get latestWaist {
    for (final e in _entries.reversed) {
      if (e.waist != null) return e.waist;
    }
    return null;
  }

  /// Son kaydedilen kalça ölçümü.
  double? get latestHip {
    for (final e in _entries.reversed) {
      if (e.hip != null) return e.hip;
    }
    return null;
  }

  /// Son kaydedilen göğüs ölçümü.
  double? get latestChest {
    for (final e in _entries.reversed) {
      if (e.chest != null) return e.chest;
    }
    return null;
  }

  /// Bel değişimi (ilk kayıtlı - son kayıtlı).
  double? get waistChange {
    if (_entries.isEmpty) return null;
    final first = _firstValueWhere((e) => e.waist);
    final last = latestWaist;
    if (first == null || last == null || first == last) return null;
    return last - first;
  }

  /// Kalça değişimi.
  double? get hipChange {
    if (_entries.isEmpty) return null;
    final first = _firstValueWhere((e) => e.hip);
    final last = latestHip;
    if (first == null || last == null || first == last) return null;
    return last - first;
  }

  /// Göğüs değişimi.
  double? get chestChange {
    if (_entries.isEmpty) return null;
    final first = _firstValueWhere((e) => e.chest);
    final last = latestChest;
    if (first == null || last == null || first == last) return null;
    return last - first;
  }

  /// Listede belirli bir alanı null olmayan ilk kaydın değerini döner.
  double? _firstValueWhere(double? Function(ProgressEntryModel) selector) {
    for (final entry in _entries) {
      final val = selector(entry);
      if (val != null) return val;
    }
    return null;
  }

  /// Ardışık gün serisi — bugünden geriye doğru kesintisiz kayıt sayısı.
  int get currentStreak {
    if (_entries.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    final dateSet = _entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet();

    while (dateSet.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Veri yükleme ──────────────────────────────────────────────────────────

  /// Kullanıcının ilerleme kayıtlarını Firestore'dan dinlemeye başlar.
  void startListening(String userId, UserProfileModel? userProfile) {
    _earnedBadgeIds = List<String>.from(userProfile?.earnedBadges ?? []);
    _isLoading = true;
    notifyListeners();

    _entriesSubscription?.cancel();
    _entriesSubscription = _firestoreService
        .getProgressEntries(userId, limitDays: 90)
        .listen(
          (entries) {
            _entries = entries;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (e) {
            _isLoading = false;
            _errorMessage = 'Veriler yüklenemedi: $e';
            debugPrint('ProgressProvider stream hatası: $e');
            notifyListeners();
          },
        );
  }

  void stopListening() {
    _entriesSubscription?.cancel();
    _entriesSubscription = null;
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Yeni bir ilerleme kaydı ekler ve rozet kontrolü yapar.
  Future<void> addEntry(
    String userId,
    ProgressEntryModel entry,
    UserProfileModel? userProfile,
  ) async {
    try {
      await _firestoreService.addProgressEntry(userId, entry);
      await _checkAndAwardBadges(userId, userProfile);
    } catch (e) {
      _errorMessage = 'Kayıt eklenemedi: $e';
      debugPrint('ProgressProvider addEntry hatası: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Mevcut bir kaydı günceller.
  Future<void> updateEntry(String userId, ProgressEntryModel entry) async {
    try {
      await _firestoreService.updateProgressEntry(userId, entry);
    } catch (e) {
      _errorMessage = 'Kayıt güncellenemedi: $e';
      debugPrint('ProgressProvider updateEntry hatası: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Bir kaydı siler.
  Future<void> deleteEntry(String userId, String entryId) async {
    try {
      await _firestoreService.deleteProgressEntry(userId, entryId);
    } catch (e) {
      _errorMessage = 'Kayıt silinemedi: $e';
      debugPrint('ProgressProvider deleteEntry hatası: $e');
      notifyListeners();
      rethrow;
    }
  }

  // ── Rozet sistemi ─────────────────────────────────────────────────────────

  /// Mevcut duruma göre yeni rozetleri kontrol eder ve kazanılanları kaydeder.
  Future<List<String>> _checkAndAwardBadges(
    String userId,
    UserProfileModel? userProfile,
  ) async {
    final newlyEarned = <String>[];

    void check(String badgeId, bool condition) {
      if (condition && !_earnedBadgeIds.contains(badgeId)) {
        _earnedBadgeIds.add(badgeId);
        newlyEarned.add(badgeId);
      }
    }

    // İlk kayıt rozeti
    check('first_entry', _entries.isNotEmpty);

    // Seri rozetleri
    check('streak_7', currentStreak >= 7);
    check('streak_30', currentStreak >= 30);

    // Kilo kaybı rozetleri
    final change = totalWeightChange;
    check('lost_1kg', change <= -1.0);
    check('lost_5kg', change <= -5.0);

    // Hedef kilo rozeti
    final goalWeight = userProfile?.weight;
    if (goalWeight != null && latestWeight != null) {
      final change = totalWeightChange;
      if (change <= -5.0) {
        check('goal_reached', true);
      }
    }

    // Ölçüm ekleme rozeti
    final hasMeasurement = _entries.any(
      (e) => e.waist != null || e.hip != null || e.chest != null,
    );
    check('measurement_added', hasMeasurement);

    if (newlyEarned.isNotEmpty) {
      try {
        await _firestoreService.saveEarnedBadges(userId, _earnedBadgeIds);
        notifyListeners();
      } catch (e) {
        debugPrint('Rozet kaydetme hatası: $e');
      }
    }

    return newlyEarned;
  }

  /// Fotoğraf eklendi rozeti — dışarıdan tetiklenir.
  Future<void> awardPhotoAddedBadge(String userId) async {
    if (!_earnedBadgeIds.contains('photo_added')) {
      _earnedBadgeIds.add('photo_added');
      try {
        await _firestoreService.saveEarnedBadges(userId, _earnedBadgeIds);
        notifyListeners();
      } catch (e) {
        debugPrint('Fotoğraf rozeti kaydetme hatası: $e');
      }
    }
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    super.dispose();
  }
}
