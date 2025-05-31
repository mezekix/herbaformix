import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Diğer ekranlar eklenecek...
// import '../features/products/screens/product_list_screen.dart';
// import '../features/orders/screens/order_list_screen.dart';
// import '../features/customers/screens/customer_list_screen.dart';

import '../features/auth/providers/auth_provider.dart';
// Ekranları import edeceğiz (henüz oluşturulmadılar)
import '../features/auth/screens/login_screen.dart'; // Yönlendirme için bir splash ekran
import '../features/profile/screens/profile_screen.dart';

class AppRouter {
  final AuthProvider authProvider; // AuthProvider'ı alacağız

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true, // Geliştirme sırasında logları görmek için
    refreshListenable: authProvider, // Auth durumu değiştiğinde router'ı yenile
    initialLocation: SplashScreen.routeName, // Başlangıç rotası

    routes: <RouteBase>[
      GoRoute(
        path: SplashScreen.routeName,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: LoginScreen.routeName,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: HomeScreen.routeName,
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen(); // Örnek bir ana sayfa
        },
        // Diğer alt rotalar (örneğin /home/profile) buraya eklenebilir
        routes: <RouteBase>[
          GoRoute(
            path: 'profile', // /home/profile
            name: ProfileScreen.routeName, // İsimlendirilmiş rota
            builder: (context, state) => const ProfileScreen(),
          ),
          // TODO: Ürünler, Siparişler, Müşteriler için rotalar eklenecek
        ],
      ),
      // TODO: Ürünler, Siparişler, Müşteriler için ana rotalar eklenecek
      // GoRoute(
      //   path: ProductListScreen.routeName,
      //   builder: (context, state) => const ProductListScreen(),
      // ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authProvider.status == AuthStatus.authenticated;
      final bool loggingIn = state.matchedLocation == LoginScreen.routeName;
      final bool splicing = state.matchedLocation == SplashScreen.routeName;

      if (splicing) {
        // Eğer splash ekranındaysa, auth durumuna göre yönlendir
        if (authProvider.status == AuthStatus.uninitialized ||
            authProvider.status == AuthStatus.authenticating) {
          return null; // Splash ekranında kal, authProvider durumu belirleyecek
        }
        return loggedIn ? HomeScreen.routeName : LoginScreen.routeName;
      }

      if (!loggedIn && !loggingIn) {
        // Giriş yapmamış ve giriş sayfasında değilse
        return LoginScreen.routeName; // Giriş sayfasına yönlendir
      }
      if (loggedIn && loggingIn) {
        // Giriş yapmış ve hala giriş sayfasındaysa
        return HomeScreen.routeName; // Ana sayfaya yönlendir
      }

      return null; // Başka bir yönlendirme gerekmiyorsa null döndür
    },
  );
}

// Örnek Ekranlar (Bunları kendi dosyalarına taşıyacağız)

class SplashScreen extends StatelessWidget {
  // Bu dosyada geçici olarak tanımlıyoruz
  static const String routeName = '/splash';
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthProvider'ın durumuna göre yönlendirme zaten redirect'te yapılıyor
    // Kullanıcıya yükleniyor gibi bir ekran gösterebilirsiniz.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class HomeScreen extends StatelessWidget {
  // Bu dosyada geçici olarak tanımlıyoruz
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('HerbaForm Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              // Yönlendirme redirect tarafından otomatik yapılacak
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.goNamed(ProfileScreen.routeName); // Profil sayfasına git
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Hoş geldiniz, ${authProvider.user?.email ?? 'Kullanıcı'}!',
        ),
      ),
    );
  }
}
