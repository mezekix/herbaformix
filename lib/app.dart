import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router.dart';
import 'features/auth/providers/auth_provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _appRouter; // AppRouter'ı tanımla

  @override
  void initState() {
    super.initState();
    // AuthProvider'ı al ve AppRouter'ı başlat
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _appRouter = AppRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HerbaForm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green, // Herbalife renklerine uygun bir tema seçebilirsiniz
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _appRouter.router, // GoRouter yapılandırmasını kullan
    );
  }
}