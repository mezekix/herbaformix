import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'features/auth/providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'features/products/providers/product_provider.dart'; // ProductProvider'ı import et

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        Provider<AuthService>(
          create: (_) => authService,
        ),
        Provider<FirestoreService>(
          create: (_) => firestoreService,
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
            context.read<FirestoreService>(),
          ),
        ),
        // ProductProvider'ı ekle. FirestoreService'i context'ten okuyacak.
        ChangeNotifierProvider<ProductProvider>(
          create: (context) => ProductProvider(
            context.read<FirestoreService>(),
          ),
        ),
      ],
      child: const App(),
    );
  }
}