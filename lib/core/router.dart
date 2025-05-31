import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/products/screens/product_list_screen.dart'; // Ürünler ekranını import et
// Diğer ekranlar eklenecek...

import '../features/auth/providers/auth_provider.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: authProvider,
    initialLocation: SplashScreen.routeName,

    routes: <RouteBase>[
      // ... (SplashScreen ve LoginScreen rotaları aynı kalacak) ...
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
          return const HomeScreen();
        },
        routes: <RouteBase>[
           GoRoute(
            path: 'profile',
            name: ProfileScreen.routeName,
            builder: (context, state) => const ProfileScreen(),
          ),
           // Ürünler ekranı için yeni rota
           GoRoute(
            path: 'products', // /home/products gibi erişim için ama biz direkt /products yapacağız.
            name: ProductListScreen.routeName.substring(1), // Baştaki / olmadan isim
            builder: (context, state) => const ProductListScreen(),
           ),
        ]
      ),
      // Ürünler için ana rota (/products)
       GoRoute(
        path: ProductListScreen.routeName, // /products
        builder: (context, state) => const ProductListScreen(),
      ),
      // TODO: Müşteriler ve Siparişler için rotalar eklenecek
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // ... (redirect mantığı aynı kalacak) ...
       final bool loggedIn = authProvider.status == AuthStatus.authenticated;
       final bool loggingIn = state.matchedLocation == LoginScreen.routeName;
       final bool splicing = state.matchedLocation == SplashScreen.routeName;

       print("Redirect: loggedIn=$loggedIn, loggingIn=$loggingIn, splicing=$splicing, location=${state.matchedLocation}");

       // Eğer Splash'teyse ve auth durumu belirsizse bekle
       if (splicing && (authProvider.status == AuthStatus.uninitialized || authProvider.status == AuthStatus.authenticating)) {
         return null;
       }
       // Eğer Splash'teyse ve auth durumu belliyse yönlendir
       if (splicing) {
         return loggedIn ? HomeScreen.routeName : LoginScreen.routeName;
       }

       // Eğer giriş yapmamışsa ve giriş sayfasında değilse, giriş sayfasına yolla
       if (!loggedIn && !loggingIn) {
         return LoginScreen.routeName;
       }
       // Eğer giriş yapmışsa ve giriş sayfasındaysa, ana sayfaya yolla
       if (loggedIn && loggingIn) {
         return HomeScreen.routeName;
       }

       return null;
    },
  );
}
// SplashScreen ve HomeScreen tanımlamaları kendi dosyalarına taşındı varsayılıyor.
