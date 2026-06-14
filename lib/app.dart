import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart'; // Yeni renk dosyamızı import ediyoruz
import 'core/locale_provider.dart';
import 'core/router.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/calorie_tracker/providers/calorie_provider.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/orders/providers/cart_provider.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/products/providers/product_provider.dart';
import 'features/products/providers/recipe_provider.dart';
import 'features/program/providers/program_provider.dart';
import 'features/program/providers/program_template_provider.dart';
import 'features/program/services/notification_service.dart';
import 'features/progress/providers/progress_provider.dart';
import 'features/water_tracker/providers/water_provider.dart';
import 'services/exercise_service.dart';
import 'services/firestore_service.dart';

/// GoRouter'ın [refreshListenable]'ı olarak kullanılır.
///
/// [AuthProvider.notifyListeners] doğrudan GoRouter'a bağlandığında,
/// aynı build frame'inde hem Provider dependentları hem de MaterialApp.router
/// dirty olarak işaretlenir. Bu iki rebuild farklı build scope'larda
/// gerçekleştiği için Flutter `_dependents.isEmpty` assertion fırlatır.
///
/// Bu sarmalayıcı, AuthProvider bildirimlerini [addPostFrameCallback] ile
/// build fazı **sonrasına** erteler ve scope çakışmasını önler.
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(AuthProvider authProvider) {
    authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    // Build fazı sırasında GoRouter refresh tetiklenmesini engelle.
    // Mevcut frame tamamlandıktan sonra güvenli bir şekilde bildirim gönder.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _appRouter;
  late final _GoRouterRefreshNotifier _refreshNotifier;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _refreshNotifier = _GoRouterRefreshNotifier(authProvider);
    _appRouter = AppRouter(authProvider, refreshListenable: _refreshNotifier);
  }

  @override
  void dispose() {
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final activeLocale = localeProvider.locale;
    // Intl tabanlı (DateFormat / NumberFormat) çıktılar seçilen dile uysun.
    Intl.defaultLocale = activeLocale?.languageCode ?? 'tr';

    return MaterialApp.router(
      title: 'HerbaForm',
      debugShowCheckedModeBanner: false,
      locale: activeLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleProvider.supportedLocales,
      theme: ThemeData(
        // Ana Renk Paleti AppColors'dan alınıyor
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.error,
          surface: AppColors.surface,
          surfaceContainerHighest: AppColors.background,
          onPrimary: AppColors.textOnPrimary, // primary üzerindeki yazı rengi
          onSecondary:
              AppColors.textOnSecondary, // secondary üzerindeki yazı rengi
          onSurface: AppColors.textPrimary, // surface üzerindeki yazı rengi
          onError: AppColors.white, // error üzerindeki yazı rengi
        ),

        // AppBar Teması
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2.0, // Daha yumuşak bir gölge
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.textOnPrimary),
        ),

        // Buton Temaları
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ), // Biraz daha büyük butonlar
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ), // Yazı kalınlığı arttı
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Daha yuvarlak kenarlar
            ),
            elevation: 2, // Buton gölgesi
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Input Alanları Teması (TextFormField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true, // Arka plan rengi için
          fillColor: AppColors.surface, // Giriş alanlarının arka planı
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide
                .none, // Varsayılan kenarlığı kaldır, fillColor ile daha iyi görünür
          ),
          enabledBorder: OutlineInputBorder(
            // Odaklanılmamış durum
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
          ), // Label rengi
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIconColor: AppColors.primary.withAlpha(
            179,
          ), // withOpacity(0.7) yerine
          floatingLabelStyle: const TextStyle(
            color: AppColors.primary,
          ), // Odaklanınca label rengi
        ),

        // Diğer genel tema ayarları
        scaffoldBackgroundColor: AppColors.background,
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 22,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            fontSize: 20,
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
          ), // Varsayılan metin
          bodyMedium: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ), // İkincil metinler
          labelLarge: const TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ), // Butonlar için
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent, // Vurgu rengi (mango)
          // a11y: mango üstünde beyaz 1.95:1 — WCAG AA fail. Koyu metin (nightSky)
          // ~10.8:1 sağlar.
          foregroundColor: AppColors.nightSky,
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
        ),

        iconTheme: IconThemeData(
          // Genel ikon teması
          color: AppColors.primary.withAlpha(230), // withOpacity(0.9) yerine
          size: 24,
        ),

        listTileTheme: ListTileThemeData(
          // ListTile için varsayılanlar
          iconColor: AppColors.primary,
          titleTextStyle: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          subtitleTextStyle: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _appRouter.router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ProductProvider>(
              create: (context) =>
                  ProductProvider(context.read<FirestoreService>()),
            ),
            ChangeNotifierProvider<RecipeProvider>(
              create: (context) => RecipeProvider()..loadRecipes(),
            ),
            ChangeNotifierProvider<CustomerProvider>(
              create: (context) => CustomerProvider(
                context.read<FirestoreService>(),
                context.read<AuthProvider>(),
              ),
            ),
            ChangeNotifierProvider<OrderProvider>(
              create: (context) => OrderProvider(
                context.read<FirestoreService>(),
                context.read<AuthProvider>(),
                context.read<CustomerProvider>(),
              ),
            ),
            ChangeNotifierProvider<CartProvider>(
              create: (context) => CartProvider(),
            ),
            ChangeNotifierProvider<HomeProvider>(
              create: (context) => HomeProvider(
                context.read<FirestoreService>(),
                context.read<AuthProvider>(),
              ),
            ),
            ChangeNotifierProxyProvider<AuthProvider, WaterProvider>(
              create: (context) =>
                  WaterProvider(context.read<FirestoreService>()),
              update: (context, auth, previous) {
                final provider = previous ??
                    WaterProvider(context.read<FirestoreService>());
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (auth.status == AuthStatus.authenticated &&
                      auth.firebaseUser?.uid != null) {
                    provider.startListening(auth.firebaseUser!.uid);
                  } else {
                    provider.stopListening();
                  }
                });
                return provider;
              },
            ),
            ChangeNotifierProxyProvider<AuthProvider, ExerciseService>(
              create: (_) => ExerciseService(),
              update: (context, auth, previous) {
                final provider = previous ?? ExerciseService();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (auth.status == AuthStatus.authenticated &&
                      auth.firebaseUser?.uid != null) {
                    provider.startListening(auth.firebaseUser!.uid);
                  } else {
                    provider.stopListening();
                  }
                });
                return provider;
              },
            ),
            ChangeNotifierProxyProvider<AuthProvider, CalorieProvider>(
              create: (_) => CalorieProvider(),
              update: (context, auth, previous) {
                final provider = previous ?? CalorieProvider();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (auth.status == AuthStatus.authenticated &&
                      auth.firebaseUser?.uid != null) {
                    provider.startListening(auth.firebaseUser!.uid);
                  } else {
                    provider.stopListening();
                  }
                });
                return provider;
              },
            ),
            ChangeNotifierProvider<ProgramProvider>(
              create: (context) => ProgramProvider(
                notificationService: NotificationService(),
              ),
            ),
            ChangeNotifierProvider<ProgramTemplateProvider>(
              create: (context) => ProgramTemplateProvider(),
            ),
            ChangeNotifierProvider<ProgressProvider>(
              create: (context) => ProgressProvider(
                context.read<FirestoreService>(),
              ),
            ),
          ],
          child: child,
        );
      },
    );
  }
}

