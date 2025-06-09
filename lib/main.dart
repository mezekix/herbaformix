import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tarih formatlama için lokalizasyon
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/home/providers/home_provider.dart'; // Yeni provider'ı import ediyoruz.
import 'features/orders/providers/order_provider.dart'; // OrderProvider'ı import et
import 'features/products/providers/product_provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting(
    'tr_TR',
    null,
  ); // Türkçe tarih formatlaması için
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
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
            context.read<FirestoreService>(),
          ),
        ),
        ChangeNotifierProvider<ProductProvider>(
          create: (context) =>
              ProductProvider(context.read<FirestoreService>()),
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
      ],
      child: const App(),
    );
  }
}
