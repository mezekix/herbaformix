import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // redirect içinde Provider.of veya context.read için gerekli

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/customers/screens/add_edit_customer_screen.dart';
import '../features/customers/screens/customer_detail_screen.dart';
import '../features/customers/screens/customer_list_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/orders/screens/add_edit_order_screen.dart';
import '../features/orders/screens/order_list_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class AppRouter {
  final AuthProvider authProvider;
  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable:
        authProvider, // Auth durumu değiştiğinde rotaları yeniden değerlendirir.
    initialLocation: SplashScreen.routeName, // Başlangıç her zaman Splash
    routes: <RouteBase>[
      GoRoute(
        path: SplashScreen.routeName, // '/splash'
        name: SplashScreen.routeName.substring(1), // 'splash'
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routeName, // '/login'
        name: LoginScreen.routeName.substring(1), // 'login'
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: HomeScreen.routeName, // '/home'
        name: HomeScreen.routeName.substring(1), // 'home'
        builder: (context, state) => const HomeScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'profile', // '/home/profile'
            name: ProfileScreen
                .routeName, // ProfileScreen.routeName = 'profile' olmalı
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'products', // '/home/products'
            name: ProductListScreen.routeName.substring(
              1,
            ), // 'products' (Eğer PLS.routeName = '/products')
            // veya ProductListScreen.routeName (Eğer PLS.routeName = 'products')
            builder: (context, state) => const ProductListScreen(),
            routes: [
              GoRoute(
                path: ProductDetailScreen.routeName, // 'product-detail'
                name: ProductDetailScreen.routeName,
                builder: (context, state) {
                  final product = state.extra as ProductModel?;
                  if (product != null) {
                    return ProductDetailScreen(product: product);
                  }
                  return const Scaffold(
                    body: Center(child: Text('Ürün bulunamadı!')),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'customers', // '/home/customers'
            name: CustomerListScreen.routeName.substring(
              1,
            ), // 'customers' (Eğer CLS.routeName = '/customers')
            builder: (context, state) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: AddEditCustomerScreen.routeName, // 'add-edit-customer'
                name: AddEditCustomerScreen.routeName,
                builder: (context, state) {
                  final customer = state.extra as CustomerModel?;
                  return AddEditCustomerScreen(customer: customer);
                },
              ),
              GoRoute(
                path: CustomerDetailScreen.routeName, // 'customer-detail'
                name: CustomerDetailScreen.routeName,
                builder: (context, state) {
                  final customer = state.extra as CustomerModel;
                  return CustomerDetailScreen(customer: customer);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'orders', // '/home/orders'
            name: OrderListScreen.routeName.substring(
              1,
            ), // 'orders' (Eğer OLS.routeName = '/orders')
            builder: (context, state) => const OrderListScreen(),
            routes: [
              GoRoute(
                path: AddEditOrderScreen.routeName, // 'add-edit-order'
                name: AddEditOrderScreen.routeName,
                builder: (context, state) {
                  final order = state.extra as OrderModel?;
                  return AddEditOrderScreen(order: order);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // DOĞRU YÖNLENDİRME MANTIĞI:
      final auth = context.read<AuthProvider>();
      final bool loggedIn = auth.status == AuthStatus.authenticated;
      final String currentLocation = state.matchedLocation;
      final String currentPath = state.uri.toString(); // Tam path'i almak için

      print(
        "[Redirect Check] Path: $currentPath, Location: $currentLocation, AuthStatus: ${auth.status}, LoggedIn: $loggedIn",
      );

      // Eğer Splash Screen'deysek, Splash kendi yönlendirmesini yapacak.
      if (currentLocation == SplashScreen.routeName ||
          currentPath == SplashScreen.routeName) {
        print("[Redirect Decision] Splash'te kalınıyor.");
        return null;
      }

      // Eğer kullanıcı giriş yapmışsa:
      if (loggedIn) {
        // Eğer Login sayfasındaysa, Ana Sayfa'ya yönlendir.
        if (currentLocation == LoginScreen.routeName ||
            currentPath == LoginScreen.routeName) {
          print(
            "[Redirect Decision] Giriş yapıldı, Login ekranında -> Ana Sayfa'ya yönlendiriliyor ($HomeScreen.routeName).",
          );
          return HomeScreen.routeName; // '/home'
        }
        // Diğer durumlarda (Home, Profile vb.) yönlendirme yapma, olduğu yerde kal.
        print(
          "[Redirect Decision] Giriş yapıldı, $currentLocation ekranında -> Kalınıyor.",
        );
        return null;
      }
      // Eğer kullanıcı giriş yapmamışsa:
      else {
        // Eğer Login sayfasında değilse (ve Splash de değil), Login'e yönlendir.
        if (currentLocation != LoginScreen.routeName &&
            currentPath != LoginScreen.routeName) {
          print(
            "[Redirect Decision] Giriş yapılmamış, $currentLocation ekranında -> Login'e yönlendiriliyor ($LoginScreen.routeName).",
          );
          return LoginScreen.routeName; // '/login'
        }
        // Zaten Login sayfasındaysa (veya Splash'teyse), yönlendirme yapma.
        print(
          "[Redirect Decision] Giriş yapılmamış, Login ekranında -> Kalınıyor.",
        );
        return null;
      }
    },
  );
}
