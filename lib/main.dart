import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tarih formatlama için lokalizasyon
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/program/services/notification_service.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/routine_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestore offline persistence — okumalar cache'lenir, ağ kesintisinde de çalışır.
  // Mobilde varsayılan açık; web'de IndexedDB tabanlı. cacheSize sınırsız.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Tarih formatlaması hızlıdır, paralel çalışabilir
  unawaited(initializeDateFormatting('tr_TR', null));
  // runApp'ı hemen çağır — kullanıcı beyaz ekranda beklemesin
  runApp(const MyAppInitializer());
  // Bildirim servisi arka planda başlasın (lazy init zaten mevcut)
  unawaited(NotificationService().initialize());
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
      ],
      child: const App(),
    );
  }
}
