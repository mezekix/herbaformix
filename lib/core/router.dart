import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // redirect içinde Provider.of veya context.read için gerekli

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/calorie_tracker/screens/calorie_history_screen.dart';
import '../features/calorie_tracker/screens/calorie_tracker_screen.dart';
import '../features/customers/screens/add_edit_customer_screen.dart';
import '../features/customers/screens/customer_detail_screen.dart';
import '../features/customers/screens/customer_list_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/orders/screens/add_edit_order_screen.dart';
import '../features/orders/screens/cart_screen.dart';
import '../features/orders/screens/order_list_screen.dart';
import '../features/products/screens/add_edit_product_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/personal_info_screen.dart';
import '../features/profile/screens/health_goals_screen.dart';
import '../features/profile/screens/app_settings_screen.dart';
import '../features/profile/screens/support_screen.dart';
import '../features/progress/screens/progress_dashboard_screen.dart';
import '../features/progress/screens/progress_photos_screen.dart';
import '../features/progress/screens/measurements_history_screen.dart';
import '../features/progress/screens/badge_showcase_screen.dart';
import '../features/water_tracker/screens/water_tracker_screen.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_role.dart';
import '../features/auth/screens/customer_onboarding_screen.dart';
import '../features/program/screens/create_program_screen.dart';
import '../features/program/screens/edit_program_template_screen.dart';
import '../features/program/screens/program_templates_screen.dart';
import '../features/program/models/program_editor_args.dart';
import '../features/program/models/program_template_model.dart';
import 'package:herbaformix/core/logger.dart';
import '../features/follow_ups/screens/follow_up_dashboard_screen.dart';
import '../services/fcm_service.dart';

class AppRouter {
  final AuthProvider authProvider;
  final Listenable refreshListenable;
  AppRouter(this.authProvider, {required this.refreshListenable}) {
    _setupNotificationTapHandler();
  }

  void _setupNotificationTapHandler() {
    FcmService().onNotificationTap = (data) {
      AppLogger.debug('Bildirim tıklandı handler çalıştı: $data', tag: 'AppRouter');
      final type = data['type'] as String?;
      if (type == null) return;

      switch (type) {
        case 'new_program':
          router.go('/home');
          break;
        case 'daily_message':
          router.go('/home');
          break;
        case 'follow_up':
          router.go('/home/follow-ups');
          break;
      }
    };
  }

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable:
        refreshListenable, // Auth durumu değiştiğinde rotaları yeniden değerlendirir.
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
            path: CustomerOnboardingScreen.routeName,
            name: CustomerOnboardingScreen.routeName,
            builder: (context, state) => const CustomerOnboardingScreen(),
          ),
          GoRoute(
            path: CreateProgramScreen.routeName, // 'create-program'
            name: CreateProgramScreen.routeName,
            builder: (context, state) {
              final args = state.extra as ProgramEditorArgs?;
              return CreateProgramScreen(editorArgs: args);
            },
          ),
          GoRoute(
            path: ProgramTemplatesScreen.routeName, // 'program-templates'
            name: ProgramTemplatesScreen.routeName,
            builder: (context, state) => const ProgramTemplatesScreen(),
            routes: [
              GoRoute(
                path: 'edit', // '/home/program-templates/edit'
                name: EditProgramTemplateScreen.routeName,
                builder: (context, state) {
                  final existing = state.extra as ProgramTemplateModel?;
                  return EditProgramTemplateScreen(existing: existing);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'profile', // '/home/profile'
            name: ProfileScreen.routeName,
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'personal-info',
                name: 'personal-info',
                builder: (context, state) => const PersonalInfoScreen(),
              ),
              GoRoute(
                path: 'health-goals',
                name: 'health-goals',
                builder: (context, state) => const HealthGoalsScreen(),
              ),
              GoRoute(
                path: 'app-settings',
                name: 'app-settings',
                builder: (context, state) => const AppSettingsScreen(),
              ),
              GoRoute(
                path: 'support',
                name: 'support',
                builder: (context, state) => const SupportScreen(),
              ),
            ],
          ),
          GoRoute(
            path: WaterTrackerScreen.routeName, // 'water-tracker'
            name: WaterTrackerScreen.routeName,
            builder: (context, state) => const WaterTrackerScreen(),
          ),
          GoRoute(
            path: CalorieTrackerScreen.routeName, // 'calorie-tracker'
            name: CalorieTrackerScreen.routeName,
            builder: (context, state) => const CalorieTrackerScreen(),
            routes: [
              GoRoute(
                path: 'history', // '/home/calorie-tracker/history'
                name: CalorieHistoryScreen.routeName,
                builder: (context, state) => const CalorieHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: ProgressDashboardScreen.routeName,
            name: ProgressDashboardScreen.routeName,
            builder: (context, state) => const ProgressDashboardScreen(),
          ),
          GoRoute(
            path: ProgressPhotosScreen.routeName, // 'progress-photos'
            name: ProgressPhotosScreen.routeName,
            builder: (context, state) => const ProgressPhotosScreen(),
          ),
          GoRoute(
            path: MeasurementsHistoryScreen.routeName,
            name: MeasurementsHistoryScreen.routeName,
            builder: (context, state) => const MeasurementsHistoryScreen(),
          ),
          GoRoute(
            path: BadgeShowcaseScreen.routeName,
            name: BadgeShowcaseScreen.routeName,
            builder: (context, state) => const BadgeShowcaseScreen(),
          ),
          GoRoute(
            path: FollowUpDashboardScreen.routeName, // 'follow-ups'
            name: FollowUpDashboardScreen.routeName,
            builder: (context, state) => const FollowUpDashboardScreen(),
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
                path: AddEditProductScreen.routeName, // 'add-product'
                name: AddEditProductScreen.routeName,
                builder: (context, state) {
                  final product = state.extra as ProductModel?;
                  return AddEditProductScreen(product: product);
                },
              ),
              GoRoute(
                path:
                    '${ProductDetailScreen.routeName}/:productId', // 'product-detail/:productId'
                name: ProductDetailScreen.routeName,
                builder: (context, state) {
                  final productId = state.pathParameters['productId'];
                  if (productId != null) {
                    // Not: ProductDetailScreen'in kendisi bu ID'yi alıp
                    // product'ı provider'dan çekecek şekilde güncellenmeli.
                    return ProductDetailScreen(productId: productId);
                  }
                  return const Scaffold(
                    body: Center(child: Text('Ürün ID\'si bulunamadı!')),
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
            path: 'cart', // '/home/cart'
            name: 'cart',
            builder: (context, state) => const CartScreen(),
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

      AppLogger.debug(
        'Redirect Check — Path: $currentPath, AuthStatus: ${auth.status}',
        tag: 'Router',
      );

      // Eğer Splash Screen'deysek, Splash kendi yönlendirmesini yapacak.
      if (currentLocation == SplashScreen.routeName ||
          currentPath == SplashScreen.routeName) {
        AppLogger.debug("[Redirect Decision] Splash'te kalınıyor.", tag: 'Router');
        return null;
      }

      // Eğer kullanıcı giriş yapmışsa:
      if (loggedIn) {
        final isCustomer = auth.userProfile?.role == UserRole.customer;
        final isOnboarded = auth.userProfile?.isOnboarded ?? false;
        final isGoingToOnboarding = currentPath.contains(CustomerOnboardingScreen.routeName) || 
                                    currentLocation.contains(CustomerOnboardingScreen.routeName);

        if (isCustomer && !isOnboarded && !isGoingToOnboarding) {
          AppLogger.debug("[Redirect Decision] Müşteri onboarding tamamlamamış -> Onboarding'e yönlendiriliyor.", tag: 'Router');
          return '${HomeScreen.routeName}/${CustomerOnboardingScreen.routeName}';
        }

        if (isCustomer && isOnboarded && isGoingToOnboarding) {
          AppLogger.debug("[Redirect Decision] Müşteri onboarding tamamlamış ama onboarding'e gitmeye çalışıyor -> Ana Sayfa'ya yönlendiriliyor.", tag: 'Router');
          return HomeScreen.routeName;
        }

        // Eğer Login sayfasındaysa, Ana Sayfa'ya yönlendir.
        if (currentLocation == LoginScreen.routeName ||
            currentPath == LoginScreen.routeName) {
          AppLogger.debug(
            'Giriş yapıldı, Login ekranında → Ana Sayfaya yönlendiriliyor',
            tag: 'Router',
          );
          return HomeScreen.routeName; // '/home'
        }
        // Diğer durumlarda (Home, Profile vb.) yönlendirme yapma, olduğu yerde kal.
        AppLogger.debug(
          'Giriş yapıldı, $currentLocation ekranında → Kalınıyor',
          tag: 'Router',
        );
        return null;
      }
      // Eğer kullanıcı giriş yapmamışsa:
      else {
        // Eğer Login sayfasında değilse (ve Splash de değil), Login'e yönlendir.
        if (currentLocation != LoginScreen.routeName &&
            currentPath != LoginScreen.routeName) {
          AppLogger.debug(
            'Giriş yapılmamış → Login ekranına yönlendiriliyor',
            tag: 'Router',
          );
          return LoginScreen.routeName; // '/login'
        }
        // Zaten Login sayfasındaysa (veya Splash'teyse), yönlendirme yapma.
        AppLogger.debug(
          'Giriş yapılmamış, Login ekranında → Kalınıyor',
          tag: 'Router',
        );
        return null;
      }
    },
  );
}
