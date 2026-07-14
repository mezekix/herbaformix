import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StepTrackerStatus { loading, ready, permissionDenied, unavailable, error }

class StepDayRecord {
  const StepDayRecord({required this.date, required this.steps});

  final DateTime date;
  final int steps;
}

/// Telefonun hareket sensöründen günlük adımı takip eder.
///
/// Pedometer Android'de yeniden başlatmadan sonraki toplamı verdiği için, her
/// günün ilk değeri yerel başlangıç noktası olarak saklanır. Veriler şimdilik
/// yalnızca bu cihazda ve giriş yapan kullanıcıya özel anahtarda tutulur.
class StepTrackerProvider extends ChangeNotifier {
  static const _defaultGoal = 8000;
  static const _historyLimit = 30;

  StreamSubscription<StepCount>? _stepSubscription;
  SharedPreferences? _preferences;
  String? _userId;
  bool _disposed = false;

  StepTrackerStatus _status = StepTrackerStatus.loading;
  String? _errorMessage;
  int _todaySteps = 0;
  int _dailyGoal = _defaultGoal;
  int? _baseline;
  int? _lastRawSteps;
  String _activeDate = _dateKey(DateTime.now());
  Map<String, int> _history = <String, int>{};

  StepTrackerStatus get status => _status;
  String? get errorMessage => _errorMessage;
  int get todaySteps => _todaySteps;
  int get dailyGoal => _dailyGoal;
  double get progress => (_todaySteps / _dailyGoal).clamp(0.0, 1.0).toDouble();
  int get remainingSteps =>
      (_dailyGoal - _todaySteps).clamp(0, _dailyGoal).toInt();
  bool get isReady => _status == StepTrackerStatus.ready;

  List<StepDayRecord> get lastSevenDays {
    final today = _dateOnly(DateTime.now());
    return List<StepDayRecord>.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final key = _dateKey(day);
      return StepDayRecord(
        date: day,
        steps: key == _activeDate ? _todaySteps : (_history[key] ?? 0),
      );
    });
  }

  Future<void> startListening(String userId) async {
    if (_userId == userId && _stepSubscription != null) return;
    await _stepSubscription?.cancel();
    _userId = userId;
    _status = StepTrackerStatus.loading;
    _errorMessage = null;
    _notify();

    _preferences = await SharedPreferences.getInstance();
    await _loadSavedState();

    if (kIsWeb) {
      _setStatus(
        StepTrackerStatus.unavailable,
        'Adım sayar yalnızca Android ve iPhone uygulamalarında kullanılabilir.',
      );
      return;
    }

    if (Platform.isAndroid) {
      final permission = await Permission.activityRecognition.request();
      if (!permission.isGranted) {
        _setStatus(
          StepTrackerStatus.permissionDenied,
          'Adımları okuyabilmek için Fiziksel Aktivite izni gerekli.',
        );
        return;
      }
    }

    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (Object error) {
        _setStatus(
          StepTrackerStatus.unavailable,
          'Bu telefonda adım sensörüne erişilemedi.',
        );
      },
    );
    _setStatus(StepTrackerStatus.ready, null);
  }

  Future<void> requestPermissionAgain() async {
    final userId = _userId;
    if (userId == null) return;
    if (Platform.isAndroid) {
      await Permission.activityRecognition.request();
    }
    await startListening(userId);
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal.clamp(1000, 100000).toInt();
    await _preferences?.setInt(_key('goal'), _dailyGoal);
    _notify();
  }

  Future<void> _loadSavedState() async {
    _dailyGoal = _preferences?.getInt(_key('goal')) ?? _defaultGoal;
    _todaySteps = _preferences?.getInt(_key('todaySteps')) ?? 0;
    _baseline = _preferences?.getInt(_key('baseline'));
    _lastRawSteps = _preferences?.getInt(_key('lastRawSteps'));
    _activeDate = _preferences?.getString(_key('activeDate')) ?? _activeDate;
    final encodedHistory = _preferences?.getString(_key('history'));
    if (encodedHistory != null) {
      try {
        final decoded = jsonDecode(encodedHistory) as Map<String, dynamic>;
        _history = decoded.map(
          (key, value) => MapEntry(key, (value as num).toInt()),
        );
      } catch (_) {
        _history = <String, int>{};
      }
    }
    await _rolloverIfNeeded();
    _notify();
  }

  Future<void> _onStepCount(StepCount event) async {
    final rawSteps = event.steps;
    await _rolloverIfNeeded();

    if (_baseline == null || (_lastRawSteps != null && rawSteps < _lastRawSteps!)) {
      // Cihaz yeniden başlatıldıysa sistem sayacı sıfırlanır.
      _baseline = rawSteps;
      _todaySteps = 0;
    } else {
      _todaySteps = (rawSteps - _baseline!).clamp(0, 1000000).toInt();
    }
    _lastRawSteps = rawSteps;
    await _saveState();
    _notify();
  }

  Future<void> _rolloverIfNeeded() async {
    final todayKey = _dateKey(DateTime.now());
    if (_activeDate == todayKey) return;

    _history[_activeDate] = _todaySteps;
    _trimHistory();
    _activeDate = todayKey;
    _todaySteps = 0;
    _baseline = null;
    _lastRawSteps = null;
    await _saveState();
  }

  Future<void> _saveState() async {
    final preferences = _preferences;
    if (preferences == null) return;
    await Future.wait([
      preferences.setInt(_key('goal'), _dailyGoal),
      preferences.setInt(_key('todaySteps'), _todaySteps),
      preferences.setString(_key('activeDate'), _activeDate),
      preferences.setString(_key('history'), jsonEncode(_history)),
      if (_baseline != null) preferences.setInt(_key('baseline'), _baseline!),
      if (_baseline == null) preferences.remove(_key('baseline')),
      if (_lastRawSteps != null)
        preferences.setInt(_key('lastRawSteps'), _lastRawSteps!),
      if (_lastRawSteps == null) preferences.remove(_key('lastRawSteps')),
    ]);
  }

  void _trimHistory() {
    if (_history.length <= _historyLimit) return;
    final keys = _history.keys.toList()..sort();
    for (final key in keys.take(_history.length - _historyLimit)) {
      _history.remove(key);
    }
  }

  void _setStatus(StepTrackerStatus status, String? message) {
    _status = status;
    _errorMessage = message;
    _notify();
  }

  String _key(String name) => 'step_tracker_${_userId ?? 'anonymous'}_$name';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stepSubscription?.cancel();
    super.dispose();
  }
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

String _dateKey(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
