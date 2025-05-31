import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart'; // FirestoreService'i import et

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyAppInitializer());
}

class MyAppInitializer extends StatelessWidget {
  const MyAppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService =
        FirestoreService(); // FirestoreService örneği oluştur

    return MultiProvider(
      providers: [
        // AuthService'i doğrudan AuthProvider'a geçiyoruz, bu yüzden burada provide etmeye gerek yok.
        // Ancak FirestoreService'i birden fazla provider veya widget kullanabilir, bu yüzden provide edelim.
        Provider<AuthService>(create: (_) => authService),
        Provider<FirestoreService>(
          // FirestoreService'i provide et
          create: (_) => firestoreService,
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(), // AuthService'i context'ten oku
            context
                .read<FirestoreService>(), // FirestoreService'i context'ten oku
          ),
        ),
        // Diğer provider'lar buraya eklenebilir
      ],
      child: const App(),
    );
  }
}
