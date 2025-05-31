import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider'ı import et

import 'app.dart'; // Henüz oluşturmadık, bir sonraki adımda yapacağız
import 'features/auth/providers/auth_provider.dart'; // AuthProvider'ı import et (oluşturacağız)
import 'firebase_options.dart'; // flutterfire configure ile otomatik oluşur
import 'services/auth_service.dart'; // AuthService'i import et (oluşturacağız)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyAppInitializer());
}

class MyAppInitializer extends StatelessWidget {
  const MyAppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthService'i oluştur
    final authService = AuthService();

    return MultiProvider(
      providers: [
        // AuthProvider'ı global olarak erişilebilir yap
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService),
        ),
        // Diğer provider'ları buraya ekleyebilirsiniz
      ],
      child: const App(), // Ana uygulama widget'ımız
    );
  }
}
