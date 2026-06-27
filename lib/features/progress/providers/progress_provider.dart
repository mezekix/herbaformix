import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/user_profile_bmi.dart';
import '../../../models/badge_model.dart';
import '../../../models/progress_entry_model.dart';
import '../../../models/user_profile_model.dart';
import '../../../services/firestore_service.dart';
import '../models/measurement_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herbaformix/core/logger.dart';

class ProgressProvider with ChangeNotifier {
  final FirestoreService _firestoreService;

  List<ProgressEntryModel> _entries = [];
  List<String> _earnedBadgeIds = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ProgressEntryModel>>? _entriesSubscription;
  bool _isPrivacyMode = false;

  // Yeni kazanılan rozetler için callback
  static Function(String badgeId)? onBadgeEarned;

  /// Seri hesabına dahil edilen ek aktivite tarihleri (su, öğün vb.)
  Set<DateTime> _activityDates = {};

  /// Aktivite tarihlerini günceller (su dolumu, routine tamamlama gibi).
  void updateActivityDates(Set<DateTime> dates) {
    _activityDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    notifyListeners();
  }

  ProgressProvider(this._firestoreService) {
    _loadPrivacyMode();
  }

  List<ProgressEntryModel> get entries => _entries;
  List<String> get earnedBadgeIds => _earnedBadgeIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPrivacyMode => _isPrivacyMode;

  Future<void> _loadPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isPrivacyMode = prefs.getBool('privacy_mode') ?? false;
    notifyListeners();
  }

  Future<void> togglePrivacyMode() async {
    _isPrivacyMode = !_isPrivacyMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_mode', _isPrivacyMode);
    notifyListeners();
  }

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

  /// Haftalık ortalama kilo değişimi (kg/hafta).
  double get weeklyAverageChange {
    if (_entries.length < 2) return 0;
    final first = _entries.first;
    final last = _entries.last;
    final days = last.date.difference(first.date).inDays;
    if (days <= 0) return 0;
    return (last.weight - first.weight) / (days / 7);
  }

  /// En iyi hafta (en çok kilo verilen/kazanılan hafta).
  String get bestWeekSummary {
    if (_entries.length < 2) return '—';
    final isLoss = totalWeightChange < 0;
    double bestChange = 0;
    DateTime? bestWeekStart;

    for (int i = 0; i < _entries.length - 1; i++) {
      final start = _entries[i];
      // 7 günlük pencere
      final weekEnd = start.date.add(const Duration(days: 7));
      final weekEntries = _entries.where(
        (e) => !e.date.isBefore(start.date) && e.date.isBefore(weekEnd),
      ).toList();
      if (weekEntries.length >= 2) {
        final weekChange = weekEntries.last.weight - weekEntries.first.weight;
        final isGood = isLoss ? weekChange < bestChange : weekChange > bestChange;
        if (isGood || bestWeekStart == null) {
          bestChange = weekChange;
          bestWeekStart = start.date;
        }
      }
    }

    if (bestWeekStart == null) return '—';
    return '${bestChange >= 0 ? '+' : ''}${bestChange.toStringAsFixed(1)} kg (${DateFormat('d MMM', 'tr_TR').format(bestWeekStart)})';
  }

  /// Toplam kayıt sayısı.
  int get totalEntries => _entries.length;

  /// Son kaydedilen kilo — `latestFor(MeasurementType.weight)` ile aynı,
  /// kilo özel hedef/rozet mantıklarında sık kullanıldığı için kestirme.
  double? get latestWeight =>
      _entries.isNotEmpty ? _entries.last.weight : null;

  /// Verilen [type] için **null olmayan en son** kaydın değerini döner.
  /// Boş listede veya hiçbir kayıt o ölçümü içermiyorsa `null`.
  double? latestFor(MeasurementType type) {
    for (final e in _entries.reversed) {
      final v = e.valueFor(type);
      if (v != null) return v;
    }
    return null;
  }

  /// Verilen [type] için **toplam değişim**: (null olmayan son) - (null
  /// olmayan ilk). İki uçtan en az biri yoksa veya aynıysa `null`.
  double? changeFor(MeasurementType type) {
    if (_entries.isEmpty) return null;
    double? first;
    for (final entry in _entries) {
      final v = entry.valueFor(type);
      if (v != null) {
        first = v;
        break;
      }
    }
    final last = latestFor(type);
    if (first == null || last == null || first == last) return null;
    return last - first;
  }

  /// Ardışık gün serisi — bugünden geriye doğru kesintisiz kayıt sayısı.
  int get currentStreak {
    if (_entries.isEmpty && _activityDates.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    // Ölçüm tarihleri + aktivite tarihleri (su, öğün vb.)
    final dateSet = <DateTime>{};
    for (final e in _entries) {
      dateSet.add(DateTime(e.date.year, e.date.month, e.date.day));
    }
    dateSet.addAll(_activityDates);

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
            AppLogger.error('ProgressProvider stream hatası: $e', tag: 'ProgressProvider');
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
      // BMI: entry'de açıkça set edilmişse onu kullan; yoksa profil + kilo'dan hesapla.
      final bmi = entry.bmi ?? userProfile?.bmiFor(entry.weight);
      final finalEntry = entry.copyWith(bmi: bmi);

      await _firestoreService.addProgressEntry(userId, finalEntry).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          AppLogger.debug('[ProgressProvider] addProgressEntry timeout - offline modda olabilir.', tag: 'ProgressProvider');
          throw TimeoutException('Offline write buffered');
        },
      );
      await _checkAndAwardBadges(userId, userProfile);
    } on TimeoutException catch (_) {
      AppLogger.warning('addEntry timeout — offline modda devam ediliyor', tag: 'ProgressProvider');
    } catch (e) {
      _errorMessage = 'Kayıt eklenemedi: $e';
      AppLogger.error('ProgressProvider addEntry hatası: $e', tag: 'ProgressProvider', error: e);
      notifyListeners();
      rethrow;
    }
  }

  /// Mevcut bir kaydı günceller.
  Future<void> updateEntry(
    String userId, 
    ProgressEntryModel entry,
    [UserProfileModel? userProfile]
  ) async {
    try {
      // BMI: entry'de açıkça set edilmişse onu kullan; yoksa profil + kilo'dan hesapla.
      final bmi = entry.bmi ?? userProfile?.bmiFor(entry.weight);
      final finalEntry = entry.copyWith(bmi: bmi);

      await _firestoreService.updateProgressEntry(userId, finalEntry).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          AppLogger.debug('[ProgressProvider] updateProgressEntry timeout - offline modda olabilir.', tag: 'ProgressProvider');
          throw TimeoutException('Offline write buffered');
        },
      );
    } on TimeoutException catch (_) {
      AppLogger.warning('updateEntry timeout — offline modda devam ediliyor', tag: 'ProgressProvider');
    } catch (e) {
      _errorMessage = 'Kayıt güncellenemedi: $e';
      AppLogger.error('ProgressProvider updateEntry hatası: $e', tag: 'ProgressProvider', error: e);
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
      AppLogger.error('ProgressProvider deleteEntry hatası: $e', tag: 'ProgressProvider', error: e);
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
    final goalWeight = userProfile?.targetWeight;
    if (goalWeight != null && latestWeight != null) {
      // Kilo verme hedefi: mevcut kilo hedef kiloya eşit veya altındaysa
      if (userProfile?.userGoal == 'weight_loss' && latestWeight! <= goalWeight) {
        check('goal_reached', true);
      }
      // Kilo alma hedefi: mevcut kilo hedef kiloya eşit veya üstündeyse
      else if (userProfile?.userGoal == 'weight_gain' && latestWeight! >= goalWeight) {
        check('goal_reached', true);
      }
      // Genel: hedefe ulaşıldıysa (eşitse)
      else if (latestWeight == goalWeight) {
        check('goal_reached', true);
      }
    }

    // Ölçüm ekleme rozeti
    final hasMeasurement = _entries.any(
      (e) => e.waist != null || e.belly != null || e.hip != null || e.chest != null ||
             e.arm != null || e.thigh != null ||
             e.bodyFat != null || e.muscleMass != null,
    );
    check('measurement_added', hasMeasurement);

    if (newlyEarned.isNotEmpty) {
      try {
        await _firestoreService.saveEarnedBadges(userId, _earnedBadgeIds).timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            AppLogger.debug('[ProgressProvider] saveEarnedBadges timeout - offline modda olabilir.', tag: 'ProgressProvider');
          },
        );
        // Rozet kazanıldığında callback'i tetikle
        for (final badgeId in newlyEarned) {
          onBadgeEarned?.call(badgeId);
        }
        notifyListeners();
      } catch (e) {
        AppLogger.error('Rozet kaydetme hatası: $e', tag: 'ProgressProvider', error: e);
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
        AppLogger.error('Fotoğraf rozeti kaydetme hatası: $e', tag: 'ProgressProvider', error: e);
      }
    }
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    super.dispose();
  }
}
