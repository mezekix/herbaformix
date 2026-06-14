import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — **top-level** olmak ZORUNDA (FCM gereği).
/// Bu fonksiyon, uygulama tamamen kapalıyken bile yeni bir izolatta çağrılır;
/// bu nedenle global state'e veya UI'a erişemez. Yalnızca log + minimum işlem.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FcmService][bg] mesaj alındı: ${message.messageId} '
      'data=${message.data}');
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
        debugPrint('[FcmService] token yenilendi');
        onTokenRefresh?.call(newToken);
      });

      // 4) Foreground mesaj — local notification olarak göster.
      _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);

      // 5) Bildirime tıklayınca (uygulama arka plandayken).
      _openedFromBgSub?.cancel();
      _openedFromBgSub = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) {
          debugPrint('[FcmService] arka plandan açıldı: ${message.data}');
          onNotificationTap?.call(message.data);
        },
      );

      // 6) Uygulama tamamen kapalıyken bildirime tıklanmışsa initial mesajı al.
      final initialMessage = await _fm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '[FcmService] initial message: ${initialMessage.data}');
        // Router henüz hazır olmayabilir; küçük gecikmeyle çağır.
        Future.delayed(const Duration(milliseconds: 500), () {
          onNotificationTap?.call(initialMessage.data);
        });
      }

      _initialized = true;
      debugPrint('[FcmService] initialize tamam.');
    } catch (e) {
      debugPrint('[FcmService] initialize hatası: $e');
    }
  }

  /// Bildirim iznini ister. Onboarding'den ve Ayarlar ekranından çağrılabilir.
  /// İzin verildiyse `true`.
  Future<bool> requestPermission() async {
    try {
      final settings = await _fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      debugPrint('[FcmService] izin durumu: ${settings.authorizationStatus}');
      return granted;
    } catch (e) {
      debugPrint('[FcmService] requestPermission hatası: $e');
      return false;
    }
  }

  /// Cihazın güncel FCM token'ını döner.
  /// iOS'ta APNs token gelmeden FCM token üretilmez — kısaca bekler.
  /// Token alınamadıysa `null`.
  Future<String?> getToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final apns = await _fm.getAPNSToken();
        if (apns == null) {
          // APNs token henüz hazır değil — bir defa daha dene.
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      return await _fm.getToken();
    } catch (e) {
      debugPrint('[FcmService] getToken hatası: $e');
      return null;
    }
  }

  /// Token'ı silmek için (oturum kapatıldığında).
  Future<void> deleteToken() async {
    try {
      await _fm.deleteToken();
    } catch (e) {
      debugPrint('[FcmService] deleteToken hatası: $e');
    }
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    debugPrint('[FcmService][fg] data=${message.data}, '
        'notification=${message.notification?.title}');
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
      debugPrint('[FcmService] foreground local show hatası: $e');
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
      debugPrint('[FcmService] _ensureAndroidChannel hatası: $e');
    }
  }
}
