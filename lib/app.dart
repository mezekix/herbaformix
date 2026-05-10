import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart'; // Yeni renk dosyamızı import ediyoruz
import 'core/router.dart';
import 'features/auth/providers/auth_provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _appRouter = AppRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HerbaForm',
      debugShowCheckedModeBanner: false,
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
          backgroundColor: AppColors.accent, // Vurgu rengi
          foregroundColor: AppColors.textOnPrimary,
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
    );
  }
}
