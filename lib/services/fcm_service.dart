import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:herbaformix/core/logger.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — **top-level** olmak ZORUNDA (FCM gereği).
/// Bu fonksiyon, uygulama tamamen kapalıyken bile yeni bir izolatta çağrılır;
/// bu nedenle global state'e veya UI'a erişemez. Yalnızca log + minimum işlem.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.debug('Arka plan mesajı alındı: ${message.messageId}', tag: 'FcmService');
}

/// Firebase Cloud Messaging (FCM) wrapper'ı.
///
/// Sorumluluklar:
/// - Init + izin akışı (iOS için APNs token bekleme dahil)
/// - Token alma / yenileme stream'i
/// - Foreground / background / terminated state mesaj handler'ları
/// - Foreground'da gelen `notification` payload'unu `flutter_local_notifications`
///   ile göster (FCM foreground'da OS bildirimi göstermez)
/// - Bildirime tıklayınca deep-link callback'i tetikleme
///
/// Backend tarafı (Cloud Functions) Faz 14'ün **2. adımı** kapsamında.
/// Bu sınıf yalnızca client tarafıdır.
class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  /// Firebase Console > Cloud Messaging > Web Push certificates alanındaki
  /// public key release build'e bu adla verilmelidir.
  static const String _webVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
  );

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedFromBgSub;

  /// Token yenilendiğinde çağrılır (AuthProvider tarafından set edilir).
  /// İmza: `(String newToken) -> void`.
  void Function(String token)? onTokenRefresh;

  /// Bildirime tıklandığında çağrılır (router tarafından set edilir).
  /// İmza: `(Map<String, dynamic> data) -> void`.
  /// `data` içinde örn. `{'type': 'new_program', 'programId': '...'}` olur.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  // ── Foreground bildirim kanalı (FCM mesajlarını local olarak göstermek için)
  static const String _fcmChannelId = 'fcm_default_v1';
  static const String _fcmChannelName = 'Genel Bildirimler';

  /// Stream + handler'ları bir kez kurar. `main.dart`'tan çağrılmalı.
  /// İzin İSTEMEZ — izin akışı [requestPermission] ile ayrı tetiklenir.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // 1) Foreground notification gösterim ayarı (iOS).
      await _fm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2) Android için foreground'da bildirim göstermek üzere kanal kur.
      await _ensureAndroidChannel();

      // 3) Token yenileme stream'i.
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fm.onTokenRefresh.listen((newToken) {
        AppLogger.info('Token yenilendi', tag: 'FcmService');
        onTokenRefresh?.call(newToken);
      });

      // 4) Foreground mesaj — local notification olarak göster.
      _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);

      // 5) Bildirime tıklayınca (uygulama arka plandayken).
      _openedFromBgSub?.cancel();
      _openedFromBgSub = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) {
          AppLogger.debug('Bildirimden açıldı, type: ${message.data['type']}', tag: 'FcmService');
          onNotificationTap?.call(message.data);
        },
      );

      // 6) Uygulama tamamen kapalıyken bildirime tıklanmışsa initial mesajı al.
      final initialMessage = await _fm.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.debug('Initial message, type: ${initialMessage.data['type']}', tag: 'FcmService');
        // Router henüz hazır olmayabilir; küçük gecikmeyle çağır.
        Future.delayed(const Duration(milliseconds: 500), () {
          onNotificationTap?.call(initialMessage.data);
        });
      }

      _initialized = true;
      AppLogger.info('Initialize tamam', tag: 'FcmService');
    } catch (e) {
      AppLogger.error('Initialize hatası', tag: 'FcmService', error: e);
    }
  }

  /// Bildirim iznini ister. Onboarding'den ve Ayarlar ekranından çağrılabilir.
  /// İzin verildiyse `true`.
  Future<bool> requestPermission() async {
    try {
      if (!await _fm.isSupported()) {
        AppLogger.warning(
          'Bu tarayıcı FCM bildirimlerini desteklemiyor',
          tag: 'FcmService',
        );
        return false;
      }
      final settings = await _fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      AppLogger.info('İzin durumu: ${settings.authorizationStatus}', tag: 'FcmService');
      return granted;
    } catch (e) {
      AppLogger.error('requestPermission hatası', tag: 'FcmService', error: e);
      return false;
    }
  }

  /// İşletim sistemi/tarayıcı bildirim izninin güncel durumunu döner.
  ///
  /// Web'de `flutter_local_notifications` desteği olmadığı için ayarlar
  /// ekranı izin durumunu doğrudan FCM/browser API'sinden okumalıdır.
  Future<bool> hasPermission() async {
    try {
      if (!await _fm.isSupported()) return false;
      final settings = await _fm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      AppLogger.error(
        'Bildirim izin durumu alınamadı',
        tag: 'FcmService',
        error: e,
      );
      return false;
    }
  }

  /// Cihazın güncel FCM token'ını döner.
  /// iOS'ta APNs token gelmeden FCM token üretilmez — kısaca bekler.
  /// Token alınamadıysa `null`.
  Future<String?> getToken() async {
    try {
      if (!await hasPermission()) {
        AppLogger.debug(
          'Bildirim izni verilmediği için token istenmedi',
          tag: 'FcmService',
        );
        return null;
      }
      if (!kIsWeb && Platform.isIOS) {
        final apns = await _fm.getAPNSToken();
        if (apns == null) {
          // APNs token henüz hazır değil — bir defa daha dene.
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      if (kIsWeb) {
        if (_webVapidKey.isEmpty) {
          AppLogger.error(
            'FIREBASE_WEB_VAPID_KEY tanımlı değil; web push tokenı alınamaz',
            tag: 'FcmService',
          );
          return null;
        }
        return await _fm.getToken(
          vapidKey: _webVapidKey,
          serviceWorkerScriptPath: 'firebase-messaging-sw.js',
        );
      }
      return await _fm.getToken();
    } catch (e) {
      AppLogger.error('getToken hatası', tag: 'FcmService', error: e);
      return null;
    }
  }

  /// Token'ı silmek için (oturum kapatıldığında).
  Future<void> deleteToken() async {
    try {
      await _fm.deleteToken();
    } catch (e) {
      AppLogger.error('deleteToken hatası', tag: 'FcmService', error: e);
    }
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    AppLogger.debug('Foreground mesaj alındı, type: ${message.data['type']}', tag: 'FcmService');
    final notification = message.notification;
    if (notification == null) return;

    try {
      await _localPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _fcmChannelId,
            _fcmChannelName,
            channelDescription: 'Distribütör ve sistem bildirimleri',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      AppLogger.error('Foreground local show hatası', tag: 'FcmService', error: e);
    }
  }

  Future<void> _ensureAndroidChannel() async {
    try {
      final androidImpl = _localPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return;
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _fcmChannelId,
          _fcmChannelName,
          description: 'Distribütör ve sistem bildirimleri',
          importance: Importance.high,
        ),
      );
    } catch (e) {
      AppLogger.error('Android kanal oluşturma hatası', tag: 'FcmService', error: e);
    }
  }
}
