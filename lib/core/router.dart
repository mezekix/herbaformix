import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/customers/screens/customer_list_screen.dart';
import '../features/customers/screens/add_edit_customer_screen.dart';
import '../features/orders/screens/order_list_screen.dart';
import '../features/orders/screens/add_edit_order_screen.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';

import '../features/auth/providers/auth_provider.dart';

class AppRouter {
  final AuthProvider authProvider;
  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: authProvider,
    initialLocation: SplashScreen.routeName,
    routes: <RouteBase>[
      GoRoute(
        path: SplashScreen.routeName,
        name: SplashScreen.routeName.substring(1), // 'splash'
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routeName,
        name: LoginScreen.routeName.substring(1), // 'login'
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: HomeScreen.routeName, // '/home'
        name: HomeScreen.routeName.substring(1), // 'home'
        builder: (context, state) => const HomeScreen(),
        // Profile, Products, Customers, Orders artık HomeScreen'in alt rotaları olacak
        routes: <RouteBase>[
          GoRoute(
            path: 'profile', // '/home/profile'
            name: ProfileScreen.routeName, // ProfileScreen.routeName 'profile' olmalı
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'products', // '/home/products'
            name: ProductListScreen.routeName.substring(1), // 'products'
            builder: (context, state) => const ProductListScreen(),
          ),
          GoRoute(
            path: 'customers', // '/home/customers'
            name: CustomerListScreen.routeName.substring(1), // 'customers'
            builder: (context, state) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: AddEditCustomerScreen.routeName, // '/home/customers/add-edit-customer'
                name: AddEditCustomerScreen.routeName, // 'add-edit-customer'
                builder: (context, state) {
                  final customer = state.extra as CustomerModel?;
                  return AddEditCustomerScreen(customer: customer);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'orders', // '/home/orders'
            name: OrderListScreen.routeName.substring(1), // 'orders'
            builder: (context, state) => const OrderListScreen(),
            routes: [
              GoRoute(
                path: AddEditOrderScreen.routeName, // '/home/orders/add-edit-order'
                name: AddEditOrderScreen.routeName, // 'add-edit-order'
                builder: (context, state) {
                  final order = state.extra as OrderModel?;
                  return AddEditOrderScreen(order: order);
                },
              ),
            ],
          ),
        ],
      ),
      // Ana rotalar olarak tanımlanan ProductListScreen, CustomerListScreen, OrderListScreen
      // tanımlamalarını kaldırıyoruz, çünkü artık HomeScreen'in alt rotaları oldular.
      // GoRoute(path: ProductListScreen.routeName, name: ProductListScreen.routeName.substring(1), builder: (context, state) => const ProductListScreen()),
      // GoRoute(
      //   path: CustomerListScreen.routeName,
      //   name: CustomerListScreen.routeName.substring(1),
      //   builder: (context, state) => const CustomerListScreen(),
      //   routes: [ /* ... */ ]
      // ),
      // GoRoute(
      //   path: OrderListScreen.routeName,
      //   name: OrderListScreen.routeName.substring(1),
      //   builder: (context, state) => const OrderListScreen(),
      //   routes: [ /* ... */ ]
      // ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final auth = context.read<AuthProvider>();
      final bool loggedIn = auth.status == AuthStatus.authenticated;
      final String currentLocation = state.matchedLocation;

      if (currentLocation == SplashScreen.routeName) {
        return null;
      }

      if (loggedIn) {
        if (currentLocation == LoginScreen.routeName) {
          return HomeScreen.routeName;
        }
        return null;
      } else {
        if (currentLocation != LoginScreen.routeName) {
          return LoginScreen.routeName;
        }
        return null;
      }
    },
  );
}