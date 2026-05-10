import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tarih formatlama için lokalizasyon
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/calorie_tracker/providers/calorie_provider.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/products/providers/product_provider.dart';
import 'features/program/providers/program_provider.dart';
import 'features/program/services/notification_service.dart';
import 'features/progress/providers/progress_provider.dart';
import 'features/water_tracker/providers/water_provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/routine_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('tr_TR', null);
  // Bildirim servisini başlat
  await NotificationService().initialize();
  runApp(const MyAppInitializer());
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
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (context) => ProductProvider(context.read<FirestoreService>()),
          update: (context, auth, previous) {
            if (auth.status == AuthStatus.authenticated) {
              previous?.fetchProducts();
            }
            return previous ?? ProductProvider(context.read<FirestoreService>());
          },
        ),
        ChangeNotifierProvider<CustomerProvider>(
          create: (context) => CustomerProvider(
            context.read<FirestoreService>(),
            context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (context) => OrderProvider(
            context.read<FirestoreService>(),
            context.read<AuthProvider>(),
            context.read<CustomerProvider>(),
          ),
        ),
        ChangeNotifierProvider<HomeProvider>(
          create: (context) => HomeProvider(
            context.read<FirestoreService>(),
            context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WaterProvider>(
          create: (context) =>
              WaterProvider(context.read<FirestoreService>()),
          update: (context, auth, previous) {
            final provider =
                previous ?? WaterProvider(context.read<FirestoreService>());
            if (auth.status == AuthStatus.authenticated &&
                auth.firebaseUser?.uid != null) {
              provider.startListening(auth.firebaseUser!.uid);
            } else {
              provider.stopListening();
            }
            return provider;
          },
        ),
        ChangeNotifierProvider<CalorieProvider>(
          create: (context) => CalorieProvider(),
        ),
        ChangeNotifierProvider<ProgramProvider>(
          create: (context) => ProgramProvider(
            notificationService: NotificationService(),
          ),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (context) => ProgressProvider(
            context.read<FirestoreService>(),
          ),
        ),
      ],
      child: const App(),
    );
  }
}
