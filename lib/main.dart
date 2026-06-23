import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tarih formatlama için lokalizasyon
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/locale_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/program/services/notification_service.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/firestore_service.dart';
import 'services/routine_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Olabildiğince hızlı ve stabil başlatma: 
  // Sadece Firebase başlatılmasını bekliyoruz. Deadlock riskine karşı 15 sn timeout.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase başlatma hatası: $e');
  }

  // Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // FCM background handler kaydı
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Tarih formatlaması hızlıdır, paralel çalışabilir — tr ve en için yükle
  unawaited(initializeDateFormatting('tr_TR', null));
  unawaited(initializeDateFormatting('en_US', null));
  
  // runApp'ı hemen çağır — splash ve uygulamanın doğrudan gelmesini sağla
  runApp(const MyAppInitializer());
  
  // Bildirim ve FCM servisleri arka planda başlasın
  unawaited(NotificationService().initialize());
  unawaited(FcmService().initialize());
}

class MyAppInitializer extends StatelessWidget {
  const MyAppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
        Provider<FirestoreService>(create: (_) => firestoreService),
        Provider<RoutineService>(create: (_) => RoutineService()),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
            context.read<FirestoreService>(),
          ),
        ),
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider()..load(),
        ),
      ],
      child: const App(),
    );
  }
}
