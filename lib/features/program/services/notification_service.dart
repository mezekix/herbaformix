import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:herbaformix/core/logger.dart';
import 'package:herbaformix/services/routine_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId == 'actionSnooze') {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await plugin.initialize(settings: initSettings);

    final payload = notificationResponse.payload;
    String title = '🔔 Hatırlatma';
    String body = 'Öğününüzü/Ürününüzü almayı unutmayın!';
    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        title = data['title'] as String? ?? title;
        body = data['body'] as String? ?? body;
      } catch (_) {}
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    // Şimdilik sabit 15 dk erteleme
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 15));

    final androidDetails = const AndroidNotificationDetails(
      'meal_reminders_v4',
      'Öğün Hatırlatıcıları',
      channelDescription: 'Günlük öğün ve ürün kullanım hatırlatıcıları',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      icon: '@drawable/ic_notification',
      color: Color(0xFF7AC144),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'actionConsume',
          '✅ Tükettim',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'actionSnooze',
          '⏳ 15 Dk Ertele',
          showsUserInterface: false,
        ),
      ],
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    final reminderId = (notificationResponse.id ?? 0) + 900000;

    await plugin.zonedSchedule(
      id: reminderId,
      title: '⏳ Erteledin: $title',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

/// Öğün saatlerinde push bildirimleri yöneten servis.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Bildirim action ID sabitleri ──────────────────────────────────────────
  static const String actionOk = 'ACTION_OK';
  static const String actionView = 'ACTION_VIEW';

  // ── Kanal ID'leri ─────────────────────────────────────────────────────────
  // Android 8+ ile bir kanal oluşturulduktan sonra ses/titreşim/önem ayarları
  // değiştirilemez — yalnızca silinip yeniden oluşturulduğunda yeni ayarlar
  // geçerli olur. Bu sebeple ID'leri versiyonladık: eski sessiz kanallar
  // (`meal_reminders`, `test_channel`) initialize() sırasında silinir ve
  // aşağıdaki yeni kanallar (ses+titreşim açık) yerini alır.
  static const String _mealChannelId = 'meal_reminders_v4';
  static const String _mealChannelName = 'Öğün Hatırlatıcıları';
  static const String _testChannelId = 'test_channel_v4';
  static const String _testChannelName = 'Test Bildirimleri';

  // Hatırlatma ID offset'i (çakışmayı önler)
  // static const int _reminderIdOffset = 500000;

  // Hatırlatma süresi
  // static const Duration _reminderDelay = Duration(minutes: 15);

  // Öğün bildirim ID'leri
  static const int _morningId = 1000;
  static const int _lunchId = 1001;
  static const int _eveningId = 1002;

  /// Servisi başlatır.
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');
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
      final result = await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _initialized = result ?? false;
      if (_initialized) {
        await _setupAndroidChannels();
      }
      return _initialized;
    } catch (e) {
      AppLogger.error('initialize hatası', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Android için bildirim kanallarını ses+titreşim açık olacak şekilde
  /// (yeniden) oluşturur. Eski sessiz sürümler ('meal_reminders',
  /// 'test_channel') silinir; yeni ID'lerle (`_v2`) yerine geçer.
  /// iOS'ta no-op.
  Future<void> _setupAndroidChannels() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return;

      // 1) Eski sessiz kanalları temizle (varsa).
      await androidImpl.deleteNotificationChannel(channelId: 'meal_reminders');
      await androidImpl.deleteNotificationChannel(channelId: 'meal_reminders_v2');
      await androidImpl.deleteNotificationChannel(channelId: 'meal_reminders_v3');
      await androidImpl.deleteNotificationChannel(channelId: 'test_channel');
      await androidImpl.deleteNotificationChannel(channelId: 'test_channel_v2');
      await androidImpl.deleteNotificationChannel(channelId: 'test_channel_v3');

      // 2) Yeni kanalları oluştur (ses + titreşim açık, özel ses dosyası atanmış).
      const sound = RawResourceAndroidNotificationSound('notification_sound');
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _mealChannelId,
          _mealChannelName,
          description: 'Günlük öğün ve ürün kullanım hatırlatıcıları',
          importance: Importance.max,
          playSound: true,
          sound: sound,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _testChannelId,
          _testChannelName,
          description: 'Sistem testi için anlık bildirimler',
          importance: Importance.max,
          playSound: true,
          sound: sound,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      AppLogger.debug('Android kanalları kuruldu (özel ses aktif)', tag: 'NotificationService');
    } catch (e) {
      AppLogger.error('_setupAndroidChannels hatası', tag: 'NotificationService', error: e);
    }
  }

  /// Bildirim tıklama/aksiyon callback'i (Ön plan).
  void _onNotificationResponse(NotificationResponse response) async {
    AppLogger.debug(
      'Bildirim yanıtı: actionId=${response.actionId}, id=${response.id}',
      tag: 'NotificationService',
    );

    if (response.actionId == 'actionConsume' || response.actionId == null || response.actionId!.isEmpty) {
      try {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          final slotId = data['slotId'] as String?;
          final uid = FirebaseAuth.instance.currentUser?.uid;

          if (uid != null && slotId != null) {
            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day);
            final endOfDay = startOfDay.add(const Duration(days: 1));

            final firestore = FirebaseFirestore.instance;
            final isWater = data['isWater'] == true;

            final snapshot = await firestore
                .collection('users')
                .doc(uid)
                .collection('dailyRoutines')
                .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
                .get();

            for (var doc in snapshot.docs) {
              if (doc.data()['slotId'] != slotId) continue;

              final stepType = doc.data()['stepType'] as String?;
              final isRoutineWater = stepType == 'RoutineStepType.water' || stepType == 'water' || doc.data()['productId'] == 'water_step';

              if (isWater == isRoutineWater) {
                final routineService = RoutineService();
                await routineService.updateRoutineStatus(uid, doc.id, true);
                AppLogger.info('Öğün/Su otomatik tamamlandı: ${doc.id}', tag: 'NotificationService');
              }
            }
          }
        }
      } catch (e) {
        AppLogger.error('Otomatik işaretleme hatası', tag: 'NotificationService', error: e);
      }
    }
  }

  // /// Payload bilgisinden 15 dk sonrası için hatırlatma bildirimi zamanlar.
  // Future<void> _scheduleReminderFromPayload(int? originalId, String? payload) async {
  //   try {
  //     if (!_initialized) await initialize();
  // 
  //     final reminderId = (originalId ?? 0) + _reminderIdOffset;
  //     String title = '🔔 Hatırlatma';
  //     String body = 'Öğününüzü/Ürününüzü almayı unutmayın!';
  // 
  //     // Payload'dan orijinal başlık ve mesajı al
  //     if (payload != null && payload.isNotEmpty) {
  //       try {
  //         final data = jsonDecode(payload) as Map<String, dynamic>;
  //         title = '🔔 ${data['title'] ?? 'Hatırlatma'}';
  //         body = data['body'] as String? ?? body;
  //       } catch (_) {
  //         // JSON parse hatası → varsayılan mesaj kullan
  //       }
  //     }
  // 
  //     final scheduledDate = tz.TZDateTime.now(tz.local).add(_reminderDelay);
  // 
  //     final androidDetails = AndroidNotificationDetails(
  //       'meal_reminders',
  //       'Öğün Hatırlatıcıları',
  //       channelDescription: 'Günlük öğün ve ürün kullanım hatırlatıcıları',
  //       importance: Importance.high,
  //       priority: Priority.high,
  //       icon: '@drawable/ic_notification',
  //       color: const Color(0xFF7AC144), // AppColors.primary
  //       actions: const <AndroidNotificationAction>[
  //         AndroidNotificationAction(
  //           actionView,
  //           '🔍 İncele',
  //           showsUserInterface: true,
  //         ),
  //         AndroidNotificationAction(
  //           actionOk,
  //           '✅ Tamam',
  //           showsUserInterface: false,
  //         ),
  //       ],
  //     );
  //     const iosDetails = DarwinNotificationDetails(
  //       presentAlert: true,
  //       presentBadge: true,
  //       presentSound: true,
  //     );
  //     final details = NotificationDetails(
  //       android: androidDetails,
  //       iOS: iosDetails,
  //     );
  // 
  //     // Android 12+ exact alarm izin kontrolü
  //     await _ensureExactAlarmPermission();
  // 
  //     await _plugin.zonedSchedule(
  //       id: reminderId,
  //       title: title,
  //       body: body,
  //       scheduledDate: scheduledDate,
  //       notificationDetails: details,
  //       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //       // 1 defalık — matchDateTimeComponents null
  //     );
  // 
  //     debugPrint(
  //       '[NotificationService] ⏰ Hatırlatma zamanlandı: id=$reminderId, '
  //       'hedef=$scheduledDate (15 dk sonra)',
  //     );
  //   } catch (e) {
  //     debugPrint('[NotificationService] ❌ Hatırlatma zamanlama hatası: $e');
  //   }
  // }

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
      AppLogger.error('hasPermission hatası', tag: 'NotificationService', error: e);
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
      AppLogger.error('requestPermission hatası', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Exact alarm iznini kontrol eder ve gerekirse ister (Android 12+).
  Future<bool> _ensureExactAlarmPermission() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return true; // iOS veya bilinmeyen platform

      final canSchedule = await androidImpl.canScheduleExactNotifications();
      if (canSchedule == true) return true;

      AppLogger.warning('Exact alarm izni yok, isteniyor...', tag: 'NotificationService');
      final granted = await androidImpl.requestExactAlarmsPermission();
      AppLogger.debug('Exact alarm izni sonucu: $granted', tag: 'NotificationService');
      return granted ?? false;
    } catch (e) {
      AppLogger.error('Exact alarm izin kontrolü hatası', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Öğün bildirimi gösterir (her gün tekrarlayacak şekilde zamanlanır).
  /// Bildirimde "Tamam" ve "Daha Sonra" butonları yer alır.
  /// Hata durumunda sessizce devam eder (graceful degradation).
  Future<void> scheduleMealNotification({
    required int notificationId,
    required String title,
    required String body,
    required String scheduledTime,
    String? slotId,
    bool isWater = false,
    bool isOneTime = false,
  }) async {
    try {
      if (!_initialized) await initialize();

      // Android 12+ exact alarm izin kontrolü
      final hasExactAlarm = await _ensureExactAlarmPermission();
      if (!hasExactAlarm) {
        AppLogger.warning('Exact alarm izni verilmedi, bildirim zamanlanamayabilir', tag: 'NotificationService');
      }

      // Payload'a orijinal başlık, body ve aksiyonlar için gerekenleri kaydet
      final payload = jsonEncode({
        'title': title, 
        'body': body,
        'slotId': slotId,
        'isWater': isWater,
      });

      const sound = RawResourceAndroidNotificationSound('notification_sound');
      final androidDetails = AndroidNotificationDetails(
        _mealChannelId,
        _mealChannelName,
        channelDescription: 'Günlük öğün ve ürün kullanım hatırlatıcıları',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: sound,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public, // Kilit ekranında göster
        fullScreenIntent: true, // Ekranı uyandır
        icon: '@drawable/ic_notification',
        color: const Color(0xFF7AC144), // AppColors.primary
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'actionConsume',
            '✅ Tükettim',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'actionSnooze',
            '⏳ 15 Dk Ertele',
            showsUserInterface: false,
          ),
        ],
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav', // Özel ses
        interruptionLevel: InterruptionLevel.timeSensitive, // iOS 15+ kilit ekranında uyandırma
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Saat ve dakikayı ayrıştır ("09:30" gibi)
      final parts = scheduledTime.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      
      // Eğer saat geçtiyse yarına planla (1 dakikalık tolerans ile)
      if (scheduledDate.isBefore(now.subtract(const Duration(minutes: 1)))) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: isOneTime ? null : DateTimeComponents.time,
      );

      AppLogger.debug(
        'Bildirim zamanlandı: id=$notificationId, hedef=$scheduledDate, oneTime=$isOneTime',
        tag: 'NotificationService',
      );
    } catch (e) {
      AppLogger.error('scheduleMealNotification hatası', tag: 'NotificationService', error: e);
    }
  }

  /// Tüm program bildirimlerini iptal eder.
  Future<void> cancelAllProgramNotifications() async {
    try {
      await _plugin.cancelAll();
      AppLogger.debug('Tüm program bildirimleri iptal edildi', tag: 'NotificationService');
    } catch (e) {
      AppLogger.error('cancelAllProgramNotifications hatası', tag: 'NotificationService', error: e);
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

  /// Anında test bildirimi gönderir
  Future<void> showTestNotification() async {
    try {
      if (!_initialized) await initialize();

      final payload = jsonEncode({
        'title': 'Bildirim Testi',
        'body': 'Bildirim sistemi başarıyla çalışıyor!',
      });

      const sound = RawResourceAndroidNotificationSound('notification_sound');
      const androidDetails = AndroidNotificationDetails(
        _testChannelId,
        _testChannelName,
        channelDescription: 'Sistem testi için anlık bildirimler',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: sound,
        enableVibration: true,
        visibility: NotificationVisibility.public, // Kilit ekranında göster
        fullScreenIntent: true, // Ekranı uyandır
        icon: '@drawable/ic_notification',
        color: Color(0xFF7AC144),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            actionView,
            '🔍 İncele',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            actionOk,
            '✅ Tamam',
            showsUserInterface: false,
          ),
        ],
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav', // Özel ses
        interruptionLevel: InterruptionLevel.timeSensitive, // iOS 15+ kilit ekranında uyandırma
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: 9999,
        title: '🔔 Bildirim Testi',
        body: 'Bildirim sistemi başarıyla çalışıyor!',
        notificationDetails: details,
        payload: payload,
      );
      AppLogger.debug('Test bildirimi gönderildi', tag: 'NotificationService');
    } catch (e) {
      AppLogger.error('showTestNotification hatası', tag: 'NotificationService', error: e);
    }
  }
}
