import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgColor = Color(0xFFE6FFC5); // Açık fıstık yeşili (#e6ffc5)
  static const Color _bgGradientEnd = Color(0xFFE6FFC5); // Açık fıstık yeşili (#e6ffc5)

  // Auth durumu kontrol timeout'u: 100 × 100ms = 10 saniye
  static const int _maxAuthRetries = 100;
  int _authRetryCount = 0;

  // Büyük ekranlar için boyut sınırları
  static const double _minBgImageWidth = 80.0;
  static const double _maxBgImageWidth = 160.0;
  static const double _minLogoWidth = 220.0;
  static const double _maxLogoWidth = 360.0;

  late AnimationController _controller;

  // f1/f2 arka plan resimleri animasyonları
  late Animation<double> _bgImage1Scale;
  late Animation<double> _bgImage2Scale;
  late Alignment _bgImage1Alignment;
  late Alignment _bgImage2Alignment;

  // H Logo animasyonları
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Slogan yazısı animasyonları
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // Status bar rengini splash ile aynı yap
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: _bgColor,
      statusBarIconBrightness: Brightness.dark,
    ));

    final random = Random();

    // f1: ekranın üst bölgesinde rastgele konum (dikeyde biraz daha yukarı kaydırıldı)
    _bgImage1Alignment = Alignment(
      random.nextDouble() * 1.4 - 0.7,
      random.nextDouble() * 0.2 - 0.85, // üst kısım (ekran dışına taşmayacak şekilde dengelendi)
    );
    // f2: ekranın alt bölgesinde rastgele konum
    _bgImage2Alignment = Alignment(
      random.nextDouble() * 1.4 - 0.7,
      random.nextDouble() * 0.3 + 0.5, // alt kısım
    );

    // Toplam süre: 3 saniye
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 1) f1 resmi: %0-%35 arası scale in
    _bgImage1Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // 2) f2 resmi: %8-%40 arası scale in (biraz gecikmeli)
    _bgImage2Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.40, curve: Curves.easeOut),
      ),
    );

    // 3) H Logo: %35-%75 arası fade + scale
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );

    // 4) Slogan yazısı: %60-%100 arası slide up + fade
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
      ),
    );

    // Animasyonu başlat
    _controller.forward();

    // Animasyon bittikten sonra navigasyon
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), _checkAndNavigate);
      }
    });
  }

  void _checkAndNavigate() {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Durum henüz netleşmediyse (yükleniyorsa), 100ms gecikmeyle tekrar dene
    if (authProvider.status == AuthStatus.uninitialized ||
        authProvider.status == AuthStatus.authenticating) {
      _authRetryCount++;
      if (_authRetryCount < _maxAuthRetries) {
        Future.delayed(const Duration(milliseconds: 100), _checkAndNavigate);
        return;
      }
      // Timeout: 10 saniye geçti ama auth hâlâ netleşmedi.
      // Login'e yönlendir. Auth sonradan tamamlanırsa router redirect
      // otomatik olarak doğru sayfaya yönlendirecek.
      debugPrint(
        '[SplashScreen] Auth timeout ($_maxAuthRetries × 100ms). '
        'Status: ${authProvider.status}. Login\'e yönlendiriliyor.',
      );
    }

    final bool isLoggedIn = authProvider.status == AuthStatus.authenticated;
    if (isLoggedIn) {
      context.go(HomeScreen.routeName);
    } else {
      context.go(LoginScreen.routeName);
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double f1Width = (screenWidth * 0.30).clamp(_minBgImageWidth, _maxBgImageWidth);
    final double f2Width = (screenWidth * 0.30).clamp(_minBgImageWidth, _maxBgImageWidth);
    final double logoWidth = (screenWidth * 0.55).clamp(_minLogoWidth, _maxLogoWidth);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _bgColor,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _bgColor,
      ),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _bgColor,
                _bgGradientEnd,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            // Üstte status bar, altta nav bar boşluklarına ek 12px tampon —
            // f1/f2 saat/pil simgelerine veya alt nav'a değmesin.
            minimum: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
            children: [
              // --- Üst bölge: f1 resmi (alt kenarı H logosundan en az 24px uzakta) ---
              Expanded(
                child: Align(
                  alignment: _bgImage1Alignment,
                  child: ScaleTransition(
                    scale: _bgImage1Scale,
                    child: Image.asset(
                      'assets/f1.png',
                      width: f1Width,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // --- Ortada: H Logo + Slogan ---
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // H Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/logo/logo_h.png',
                        width: logoWidth,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            width: logoWidth,
                            height: 100,
                            child: const Center(
                              child: Text(
                                'H',
                                style: TextStyle(
                                  color: Color(0xFF1B4D26),
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Slogan
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: const Text(
                        'Doğadan gelen güç, seninle başlar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4D26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // --- Alt bölge: f2 resmi (üst kenarı slogandan en az 24px uzakta) ---
              Expanded(
                child: Align(
                  alignment: _bgImage2Alignment,
                  child: ScaleTransition(
                    scale: _bgImage2Scale,
                    child: Image.asset(
                      'assets/f2.png',
                      width: f2Width,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
