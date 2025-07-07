import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tek bir su alımını temsil eden model
class WaterLog {
  final DateTime time;
  final int amount; // ml cinsinden

  WaterLog({required this.time, required this.amount});

  // JSON serileştirme için
  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'amount': amount,
  };

  // JSON'dan nesne oluşturma için
  factory WaterLog.fromJson(Map<String, dynamic> json) =>
      WaterLog(time: DateTime.parse(json['time']), amount: json['amount']);
}

class WaterProvider with ChangeNotifier {
  static const String _prefsKey = 'water_data';
  static const int defaultGoal = 2500; // Varsayılan hedef 2.5 litre

  int _dailyGoal = defaultGoal;
  List<WaterLog> _todayLogs = [];
  bool _isLoading = false;

  WaterProvider() {
    _loadData();
  }

  // Getter'lar
  int get dailyGoal => _dailyGoal;
  List<WaterLog> get todayLogs => _todayLogs;
  int get totalConsumed {
    // Katlama (fold) ile toplamı hesapla
    return _todayLogs.fold(0, (sum, log) => sum + log.amount);
  }

  double get progress =>
      (totalConsumed / _dailyGoal).clamp(0, 1.0); // 0 ile 1 arasında sınırla
  bool get isLoading => _isLoading;

  String get todayDateKey {
    // Her gün için benzersiz bir anahtar oluştur
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // Veri Yükleme ve Kaydetme
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_prefsKey);

      if (dataString != null) {
        final Map<String, dynamic> data = json.decode(dataString);
        final todayKey = todayDateKey;

        // Kaydedilmiş hedefi yükle
        _dailyGoal = data['goal'] ?? defaultGoal;

        // Sadece bugünün verilerini yükle
        if (data.containsKey(todayKey) && data[todayKey] != null) {
          final List<dynamic> logsData = data[todayKey];
          _todayLogs = logsData.map((json) => WaterLog.fromJson(json)).toList();
        } else {
          // Yeni gün veya o güne ait kayıt yoksa, listeyi boşalt
          _todayLogs = [];
        }
      }
    } catch (e, stackTrace) {
      // Hata durumunda loglama yap ve temiz bir başlangıç sağla
      debugPrint("Su verileri yüklenirken hata oluştu: $e");
      debugPrint("Stack Trace: $stackTrace");
      _todayLogs = [];
      _dailyGoal = defaultGoal;
    } finally {
      // Her durumda yükleme durumunu false yap
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = todayDateKey;

      // Önce mevcut veriyi oku
      final dataString = prefs.getString(_prefsKey);
      Map<String, dynamic> data = {};
      if (dataString != null) {
        try {
          data = json.decode(dataString) as Map<String, dynamic>;
        } catch (e) {
          debugPrint("Mevcut su verisi okunamadı, sıfırlanıyor: $e");
          // Veri bozuksa sıfırdan başla
        }
      }

      // Mevcut veri haritasını bugünün logları ve hedefi ile güncelle
      data['goal'] = _dailyGoal;
      data[todayKey] = _todayLogs.map((log) => log.toJson()).toList();

      await prefs.setString(_prefsKey, json.encode(data));
    } catch (e) {
      debugPrint("Su verileri kaydedilirken hata oluştu: $e");
    }
  }

  // Eylemler (Actions)
  Future<void> addWater(int amount) async {
    _todayLogs.add(WaterLog(time: DateTime.now(), amount: amount));
    await _saveData();
    notifyListeners();
  }

  Future<void> removeLastLog() async {
    if (_todayLogs.isNotEmpty) {
      _todayLogs.removeLast();
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> setDailyGoal(int newGoal) async {
    if (newGoal > 0) {
      _dailyGoal = newGoal;
      await _saveData();
      notifyListeners();
    }
  }

  // Günü sıfırlama (manuel kullanım için, normalde otomatik çalışır)
  Future<void> resetDailyProgress() async {
    _todayLogs = [];
    await _saveData();
    notifyListeners();
  }
}
