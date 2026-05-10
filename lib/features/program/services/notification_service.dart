import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Öğün saatlerinde push bildirimleri yöneten servis.
/// flutter_local_notifications v21 API'si kullanılır.
/// Bildirim hataları program akışını engellemez (graceful degradation).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Öğün bildirim ID'leri
  static const int _morningId = 1000;
  static const int _lunchId = 1001;
  static const int _eveningId = 1002;
  static const List<int> _allProgramIds = [_morningId, _lunchId, _eveningId];

  /// Servisi başlatır.
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // v21: initialize() named parameter 'settings'
      final result = await _plugin.initialize(settings: initSettings);
      _initialized = result ?? false;
      return _initialized;
    } catch (e) {
      debugPrint('[NotificationService] initialize hatası: $e');
      return false;
    }
  }

  /// Bildirim iznini kontrol eder.
  Future<bool> hasPermission() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.areNotificationsEnabled();
        return granted ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('[NotificationService] hasPermission hatası: $e');
      return false;
    }
  }

  /// Bildirim iznini ister.
  Future<bool> requestPermission() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
      final iosImpl = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('[NotificationService] requestPermission hatası: $e');
      return false;
    }
  }

  /// Öğün bildirimi gösterir.
  /// Hata durumunda sessizce devam eder (graceful degradation).
  Future<void> scheduleMealNotification({
    required int notificationId,
    required String title,
    required String body,
    required String scheduledTime,
  }) async {
    try {
      if (!_initialized) await initialize();

      const androidDetails = AndroidNotificationDetails(
        'meal_reminders',
        'Öğün Hatırlatıcıları',
        channelDescription: 'Günlük öğün ve ürün kullanım hatırlatıcıları',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // v21: show() named parameters
      await _plugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );

      debugPrint(
        '[NotificationService] Bildirim gönderildi: id=$notificationId, saat=$scheduledTime',
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleMealNotification hatası: $e');
    }
  }

  /// Tüm program bildirimlerini iptal eder.
  Future<void> cancelAllProgramNotifications() async {
    try {
      for (final id in _allProgramIds) {
        // v21: cancel() named parameter 'id'
        await _plugin.cancel(id: id);
      }
      debugPrint('[NotificationService] Tüm program bildirimleri iptal edildi.');
    } catch (e) {
      debugPrint(
        '[NotificationService] cancelAllProgramNotifications hatası: $e',
      );
    }
  }

  /// Öğün anahtarından bildirim ID'si döndürür.
  static int getIdForMeal(String mealKey) {
    switch (mealKey) {
      case 'morning':
        return _morningId;
      case 'lunch':
        return _lunchId;
      case 'evening':
        return _eveningId;
      default:
        return _morningId;
    }
  }
}
