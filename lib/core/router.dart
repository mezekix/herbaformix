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
import '../features/orders/screens/order_list_screen.dart'; // OrderListScreen'i import et
import '../features/orders/screens/add_edit_order_screen.dart'; // AddEditOrderScreen'i import et
import '../models/customer_model.dart';
import '../models/order_model.dart'; // OrderModel'i extra için import et

import '../features/auth/providers/auth_provider.dart';

class AppRouter {
  final AuthProvider authProvider;
  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: authProvider,
    initialLocation: SplashScreen.routeName,
    routes: <RouteBase>[
      // ... (Mevcut Splash, Login, Home, Profile, Product, Customer rotaları) ...
      GoRoute(path: SplashScreen.routeName, builder: (context, state) => const SplashScreen()),
      GoRoute(path: LoginScreen.routeName, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
        routes: <RouteBase>[
          GoRoute(path: 'profile', name: ProfileScreen.routeName, builder: (context, state) => const ProfileScreen()),
          // Diğer alt rotalar /home altından kaldırılıp ana rotalar olarak tanımlandı.
        ],
      ),
      GoRoute(path: ProductListScreen.routeName, name: ProductListScreen.routeName.substring(1), builder: (context, state) => const ProductListScreen()),
      GoRoute(
        path: CustomerListScreen.routeName, // /customers
        name: CustomerListScreen.routeName.substring(1), // 'customers'
        builder: (context, state) => const CustomerListScreen(),
        routes: [
          GoRoute(
            path: AddEditCustomerScreen.routeName, // add-edit-customer
            name: AddEditCustomerScreen.routeName,
            builder: (context, state) {
              final customer = state.extra as CustomerModel?;
              return AddEditCustomerScreen(customer: customer);
            },
          ),
        ],
      ),
      // Siparişler için ana rota ve alt rotası
      GoRoute(
        path: OrderListScreen.routeName, // /orders
        name: OrderListScreen.routeName.substring(1), // 'orders'
        builder: (context, state) => const OrderListScreen(),
        routes: [
          GoRoute(
            path: AddEditOrderScreen.routeName, // add-edit-order
            name: AddEditOrderScreen.routeName,
            builder: (context, state) {
              final order = state.extra as OrderModel?;
              return AddEditOrderScreen(order: order);
            },
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // ... (redirect mantığı aynı kalacak) ...
       final auth = context.read<AuthProvider>();
       final bool loggedIn = auth.status == AuthStatus.authenticated;
       final bool loggingIn = state.matchedLocation == LoginScreen.routeName;
       final bool splicing = state.matchedLocation == SplashScreen.routeName;

       if (splicing && (auth.status == AuthStatus.uninitialized || auth.status == AuthStatus.authenticating)) return null;
       if (splicing) return loggedIn ? HomeScreen.routeName : LoginScreen.routeName;
       if (!loggedIn && !loggingIn) return LoginScreen.routeName;
       if (loggedIn && loggingIn) return HomeScreen.routeName;
       return null;
    },
  );
}