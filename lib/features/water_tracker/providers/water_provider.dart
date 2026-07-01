import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/water_calculation_engine.dart';
import '../../../models/user_profile_model.dart';
import '../../../models/user_role.dart';
import '../../../models/water_log_model.dart';
import '../../../models/water_summary_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/weather_service.dart';
import '../../program/models/program_model.dart';
import '../../program/services/program_service.dart';
import '../utils/water_calculation_constants.dart';
import 'package:herbaformix/core/logger.dart';

class WaterProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final ProgramService _programService = ProgramService();
  final WeatherService _weatherService = WeatherService();

  static const int defaultGoal = 2500; // ml

  String? _userId;
  UserProfileModel? _userProfile;
  ProgramModel? _activeProgram;
  WaterSummaryModel? _todaySummary;
  List<WaterLogModel> _todayLogs = [];
  bool _isLoading = false;
  bool _isDisposed = false;

  StreamSubscription<UserProfileModel?>? _profileSubscription;
  StreamSubscription<ProgramModel?>? _programSubscription;
  StreamSubscription<WaterSummaryModel?>? _summarySubscription;
  StreamSubscription<List<WaterLogModel>>? _logsSubscription;

  WaterProvider(this._firestoreService);

  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ── Getter'lar ────────────────────────────────────────────────────────────

  int get dailyGoal => _todaySummary?.targetMl ?? _userProfile?.waterDailyGoal ?? defaultGoal;
  List<WaterLogModel> get todayLogs => _todayLogs;
  bool get isLoading => _isLoading;
  UserProfileModel? get userProfile => _userProfile;
  ProgramModel? get activeProgram => _activeProgram;
  WaterSummaryModel? get todaySummary => _todaySummary;

  int get totalConsumed =>
      _todayLogs.fold(0, (sum, log) => sum + log.amount);

  double get progress =>
      (totalConsumed / dailyGoal).clamp(0.0, 1.0);

  // ── Kullanıcı bağlantısı ─────────────────────────────────────────────────

  /// Kullanıcı giriş yaptığında çağrılır — Firestore stream'ini başlatır.
  void startListening(String userId) {
    if (_userId == userId) return; // Aynı kullanıcı, tekrar başlatma
    _userId = userId;
    _isLoading = true;
    scheduleMicrotask(() => safeNotifyListeners());

    // 1. Profil değişikliklerini dinle
    _profileSubscription?.cancel();
    _profileSubscription = _firestoreService.watchUserProfile(userId).listen(
      (profile) {
        _userProfile = profile;
        _updateWaterGoal();
      },
      onError: (e) {
        AppLogger.error('WaterProvider profile stream hatası: $e', tag: 'WaterProvider');
      },
    );

    // 2. Aktif beslenme programını dinle
    _programSubscription?.cancel();
    _programSubscription = _programService.watchActiveProgram(userId).listen(
      (program) {
        _activeProgram = program;
        _updateWaterGoal();
      },
      onError: (e) {
        AppLogger.error('WaterProvider program stream hatası: $e', tag: 'WaterProvider');
      },
    );

    // 3. Günlük su özetini (egzersiz seviyesi, hava durumu vb.) dinle
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _summarySubscription?.cancel();
    _summarySubscription = _firestoreService.watchWaterSummary(userId, dateStr).listen(
      (summary) {
        if (summary != null) {
          _todaySummary = summary;
          _updateWaterGoal();
        } else {
          // Bugün için henüz özet yoksa, oluşturmayı başlat
          _initializeTodaySummary();
        }
      },
      onError: (e) {
        AppLogger.error('WaterProvider summary stream hatası: $e', tag: 'WaterProvider');
      },
    );

    // 4. Bugünün su içme loglarını dinle
    _logsSubscription?.cancel();
    _logsSubscription = _firestoreService
        .getWaterLogs(userId, DateTime.now())
        .listen(
          (logs) {
            _todayLogs = logs;
            _isLoading = false;
            safeNotifyListeners();
          },
          onError: (e) {
            AppLogger.error('WaterProvider logs stream hatası: $e', tag: 'WaterProvider');
            _isLoading = false;
            safeNotifyListeners();
          },
        );
  }

  /// Kullanıcı çıkış yaptığında çağrılır.
  void stopListening() {
    if (_userId == null) return;
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _programSubscription?.cancel();
    _programSubscription = null;
    _summarySubscription?.cancel();
    _summarySubscription = null;
    _logsSubscription?.cancel();
    _logsSubscription = null;
    _userId = null;
    _userProfile = null;
    _activeProgram = null;
    _todaySummary = null;
    _todayLogs = [];
    _isLoading = false;
    scheduleMicrotask(() => safeNotifyListeners());
  }

  // Bugünün su özetini hava durumunu da API'den çekerek hazırlar.
  Future<void> _initializeTodaySummary() async {
    if (_userId == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Şehir alanı profilde olmadığı için null geçilir (varsayılan Istanbul/Türkiye çekilir)
    final weather = await _weatherService.fetchWeather(null);

    final initialSummary = WaterSummaryModel(
      id: dateStr,
      targetMl: defaultGoal,
      exerciseLevel: WaterCalculationConstants.exerciseSedentary,
      weatherTemp: weather?.temp,
      weatherHumidity: weather?.humidity,
      weatherStatus: weather?.status,
      isWeatherFetched: weather != null,
      updatedAt: DateTime.now(),
    );

    // İlk su hedefini hesapla
    final target = WaterCalculationEngine.calculateGoal(
      profile: _userProfile ?? UserProfileModel(id: _userId!, email: '', role: UserRole.customer),
      program: _activeProgram,
      exerciseLevel: initialSummary.exerciseLevel,
      temp: initialSummary.weatherTemp,
      humidity: initialSummary.weatherHumidity,
    );

    _todaySummary = initialSummary.copyWith(targetMl: target);
    await _firestoreService.setWaterSummary(_userId!, _todaySummary!);
    safeNotifyListeners();
  }

  /// Tüm parametreleri (profil, program, egzersiz, hava durumu) harmanlayarak
  /// su hedefini dinamik olarak hesaplar ve günceller.
  Future<void> _updateWaterGoal() async {
    if (_userId == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var summary = _todaySummary;

    // Eğer özet null ise varsayılan bir taslak oluştur
    summary ??= WaterSummaryModel(
        id: dateStr,
        targetMl: defaultGoal,
        exerciseLevel: WaterCalculationConstants.exerciseSedentary,
        updatedAt: DateTime.now(),
      );

    // Hava durumu çekilmediyse ve henüz sıcaklık yoksa çekmeyi dene
    if (!summary.isWeatherFetched && summary.weatherTemp == null) {
      final weather = await _weatherService.fetchWeather(null);
      if (weather != null) {
        summary = summary.copyWith(
          weatherTemp: weather.temp,
          weatherHumidity: weather.humidity,
          weatherStatus: weather.status,
          isWeatherFetched: true,
        );
      }
    }

    // Dinamik hedef hesapla
    final calculatedGoal = WaterCalculationEngine.calculateGoal(
      profile: _userProfile ?? UserProfileModel(id: _userId!, email: '', role: UserRole.customer),
      program: _activeProgram,
      exerciseLevel: summary.exerciseLevel,
      temp: summary.weatherTemp,
      humidity: summary.weatherHumidity,
    );

    // Değişiklik varsa yerel durumu güncelle ve Firestore'a yaz
    if (calculatedGoal != summary.targetMl || _todaySummary == null || _todaySummary!.weatherTemp != summary.weatherTemp) {
      summary = summary.copyWith(
        targetMl: calculatedGoal,
        updatedAt: DateTime.now(),
      );
      _todaySummary = summary;
      safeNotifyListeners();
      await _firestoreService.setWaterSummary(_userId!, summary);
    }
  }

  // Egzersiz durumunu günceller ve hedefi yeniden hesaplar
  Future<void> setExerciseLevel(String level) async {
    if (_userId == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var summary = _todaySummary ?? WaterSummaryModel(
      id: dateStr,
      targetMl: defaultGoal,
      exerciseLevel: level,
      updatedAt: DateTime.now(),
    );

    summary = summary.copyWith(
      exerciseLevel: level,
      updatedAt: DateTime.now(),
    );

    _todaySummary = summary;
    safeNotifyListeners();

    // Yeni egzersiz durumuna göre su hedefini güncelle ve kaydet
    await _updateWaterGoal();
  }

  // ── Eylemler ─────────────────────────────────────────────────────────────

  Future<void> addWater(int amount) async {
    if (_userId == null) return;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final log = WaterLogModel(
      id: tempId,
      time: DateTime.now(),
      amount: amount,
    );

    // Optimistik güncelleme: UI'ı hemen yansıt, Firestore'u beklemeden
    _todayLogs = [..._todayLogs, log];
    safeNotifyListeners();

    try {
      await _firestoreService.addWaterLog(_userId!, log);
      // Stream gelince _todayLogs zaten doğru ID ile replace edilecek
    } catch (e) {
      // Hata halinde optimistik değişikliği geri al
      _todayLogs = _todayLogs.where((l) => l.id != tempId).toList();
      safeNotifyListeners();
      AppLogger.error('WaterProvider addWater hatası: $e', tag: 'WaterProvider', error: e);
    }
  }

  /// Son logu siler.
  Future<void> removeLastLog() async {
    if (_userId == null || _todayLogs.isEmpty) return;
    final last = _todayLogs.last;
    try {
      await _firestoreService.deleteWaterLog(_userId!, last.id);
    } catch (e) {
      AppLogger.error('WaterProvider removeLastLog hatası: $e', tag: 'WaterProvider', error: e);
    }
  }

  /// Belirli bir logu ID'siyle siler.
  Future<void> removeLog(String logId) async {
    if (_userId == null) return;
    try {
      await _firestoreService.deleteWaterLog(_userId!, logId);
    } catch (e) {
      AppLogger.error('WaterProvider removeLog hatası: $e', tag: 'WaterProvider', error: e);
    }
  }

  /// Belirli bir su logunu günceller.
  Future<void> updateWaterLog(String logId, int newAmount, DateTime newTime) async {
    if (_userId == null) return;
    try {
      final updatedLog = WaterLogModel(
        id: logId,
        time: newTime,
        amount: newAmount,
      );
      await _firestoreService.updateWaterLog(_userId!, updatedLog);
    } catch (e) {
      AppLogger.error('WaterProvider updateWaterLog hatası: $e', tag: 'WaterProvider', error: e);
    }
  }

  /// Belirli miktarda suyu geri alır (en son logdan başlayarak).
  Future<void> removeWater(int amount) async {
    if (_userId == null) return;
    int remaining = amount;
    final toDelete = <String>[];

    for (int i = _todayLogs.length - 1; i >= 0 && remaining > 0; i--) {
      if (_todayLogs[i].amount <= remaining) {
        remaining -= _todayLogs[i].amount;
        toDelete.add(_todayLogs[i].id);
      } else {
        break;
      }
    }

    // Optimistik güncelleme: UI'ı hemen yansıt
    _todayLogs = _todayLogs.where((l) => !toDelete.contains(l.id)).toList();
    safeNotifyListeners();

    for (final id in toDelete) {
      try {
        await _firestoreService.deleteWaterLog(_userId!, id);
      } catch (e) {
        AppLogger.error('WaterProvider removeWater silme hatası: $e', tag: 'WaterProvider', error: e);
      }
    }
  }

  // Manuel hedefleri distribütör veya kullanıcı istediğinde profile kaydetmek için korundu
  Future<void> setDailyGoal(int newGoal) async {
    if (_userId == null || newGoal <= 0) return;
    try {
      await _firestoreService.setWaterDailyGoal(_userId!, newGoal);
      if (_todaySummary != null) {
        _todaySummary = _todaySummary!.copyWith(targetMl: newGoal);
        await _firestoreService.setWaterSummary(_userId!, _todaySummary!);
      }
      safeNotifyListeners();
    } catch (e) {
      AppLogger.error('WaterProvider setDailyGoal hatası: $e', tag: 'WaterProvider', error: e);
    }
  }

  /// Bugünkü tüm logları siler.
  Future<void> resetDailyProgress() async {
    if (_userId == null) return;
    try {
      await _firestoreService.clearWaterLogs(_userId!, DateTime.now());
    } catch (e) {
      AppLogger.error('WaterProvider resetDailyProgress hatası: $e', tag: 'WaterProvider', error: e);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _profileSubscription?.cancel();
    _programSubscription?.cancel();
    _summarySubscription?.cancel();
    _logsSubscription?.cancel();
    super.dispose();
  }
}
