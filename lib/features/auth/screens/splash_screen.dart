import 'dart:async'; // Timer için gerekli
import 'dart:math'; // Random konumlandırma için gerekli

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // go_router için gerekli
import 'package:provider/provider.dart'; // Provider için gerekli

import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
// Kendi uygulama yapınıza göre bu import'ları düzenleyin
import '../../home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController
  _controller; // Tüm animasyonları kontrol eden ana kontrolcü
  late Animation<double> _fadeAnimation; // Ana logo için soluklaşma animasyonu
  late Animation<double>
  _scaleAnimation; // Ana logo için ölçeklendirme animasyonu
  late Animation<Offset>
  _slideAnimation; // Metin için yukarı kaydırma animasyonu

  // Arka plan resmi 1 için ölçeklendirme animasyonu
  late Animation<double> _bgImage1Scale;
  // Arka plan resmi 1 için rastgele konumlandırma (üst yarıda)
  late Alignment _bgImage1Alignment;

  // Arka plan resmi 2 için ölçeklendirme animasyonu
  late Animation<double> _bgImage2Scale;
  // Arka plan resmi 2 için rastgele konumlandırma (alt yarıda)
  late Alignment _bgImage2Alignment;

  @override
  void initState() {
    super.initState();

    // Random nesnesi oluştur
    final random = Random();

    // Arka plan resimleri için rastgele hizalamalar belirle
    // Resim 1 için ekranın üst yarısı (-1.0 ile -0.4 arası y değeri)
    _bgImage1Alignment = Alignment(
      random.nextDouble() * 1.4 - 0.7, // -0.7 ile 0.7 arasında rastgele x
      random.nextDouble() * 0.3 - 0.8, // -0.8 ile -0.5 arasında rastgele y
    );
    // Resim 2 için ekranın alt yarısı (0.4 ile 1.0 arası y değeri)
    _bgImage2Alignment = Alignment(
      random.nextDouble() * 1.4 - 0.7, // -0.7 ile 0.7 arasında rastgele x
      random.nextDouble() * 0.3 + 0.5, // 0.5 ile 0.8 arasında rastgele y
    );

    // Animasyon kontrolcüsünü başlat
    // Toplam animasyon süresi 5 saniye
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Arka plan resmi 1 için ölçeklendirme animasyonu (bounce kaldırıldı)
    _bgImage1Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.4,
          curve: Curves.easeOut,
        ), // İlk %40'ta yumuşak büyüsün
      ),
    );

    // Arka plan resmi 2 için ölçeklendirme animasyonu (bounce kaldırıldı)
    _bgImage2Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.1,
          0.5,
          curve: Curves.easeOut,
        ), // Biraz gecikmeli olarak %10-%50 arasında yumuşak büyüsün
      ),
    );

    // Ana logo için soluklaşma (fade-in) animasyonu
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.4,
          0.9,
          curve: Curves.easeOut,
        ), // %40-%80 arasında belirsin
      ),
    );

    // Ana logo için ölçeklendirme animasyonu (bounce kaldırıldı)
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.4,
          0.9,
          curve: Curves.easeOut,
        ), // %40-%90 arasında yumuşak büyüsün
      ),
    );

    // Metin için yukarı kaydırma (slide-in-up) animasyonu (bounce kaldırıldı)
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(
              0.7,
              1.0,
              curve: Curves.easeOut,
            ), // %70-%100 arasında yumuşak kaydırılsın
          ),
        );

    // Animasyonları başlat
    _controller.forward();

    // Animasyon tamamlandıktan sonra navigasyon yap
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Animasyon bittikten 1 saniye sonra navigasyon yap
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return; // Widget ağaçta hala var mı kontrol et
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final bool isLoggedIn =
              authProvider.status == AuthStatus.authenticated;

          if (isLoggedIn) {
            context.go(HomeScreen.routeName);
          } else {
            context.go(LoginScreen.routeName);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Animasyon kontrolcüsünü temizle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          // Arka plan gradyanı - Daha yumuşak pastel renkler kullanıldı
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFA5D6A7),
                Color(0xFFE1BEE7),
              ], // Pastel yeşil ve lavanta tonları
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(
                // Katmanlar halinde elemanları yerleştirmek için Stack kullanıldı
                children: [
                  // Arka plan resmi 1 (Ekranın üst yarısı)
                  Align(
                    alignment: _bgImage1Alignment,
                    child: ScaleTransition(
                      // Sadece ölçeklendirme animasyonu kullanıldı
                      scale: _bgImage1Scale,
                      child: Image.asset(
                        'assets/f1.png', // Uzantı .png
                        width:
                            MediaQuery.of(context).size.width *
                            0.30, // Daha küçük boyut (%25)
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.30,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text(
                                'Resim 1',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Arka plan resmi 2 (Ekranın alt yarısı)
                  Align(
                    alignment: _bgImage2Alignment,
                    child: ScaleTransition(
                      // Sadece ölçeklendirme animasyonu kullanıldı
                      scale: _bgImage2Scale,
                      child: Image.asset(
                        'assets/f2.png', // Uzantı .png
                        width:
                            MediaQuery.of(context).size.width *
                            0.30, // Daha küçük boyut (%25)
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.30,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text(
                                'Resim 2',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Ana içerik (logo ve metin) ortada
                  Center(
                    child: FadeTransition(
                      opacity:
                          _fadeAnimation, // Logo için soluklaşma animasyonu
                      child: ScaleTransition(
                        // Logo için ölçeklendirme animasyonu
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo resmi
                            Image.asset(
                              'assets/herbalife_logo.webp', // Uzantı .webp olarak ayarlandı
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.6, // Ekran genişliğinin %60'ı (arka plan resimlerinden büyük)
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  height: 100,
                                  color: Colors.grey[400],
                                  child: const Center(
                                    child: Text(
                                      'Herbalife Logo',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 18), // Boşluk
                            SlideTransition(
                              position:
                                  _slideAnimation, // Metin için kaydırma animasyonu
                              child: const Text(
                                'live your best life',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black38,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
