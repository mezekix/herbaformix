import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Müşteri Dashboard'unda kullanılan premium 3D animasyonlu su bardağı widget'ı.
///
/// Özellikler:
///   • Sinüs dalga animasyonu (2 katmanlı)
///   • Yükselen baloncuklar (5 adet, stagger animasyonlu)
///   • 3D perspektif tilt (Transform)
///   • Cam yansıması + glow aura
///   • Yüzde sayısal animasyonu
class AnimatedWaterGlass extends StatefulWidget {
  /// Su dolum oranı (0.0–1.0)
  final double progress;

  /// Bardak genişliği
  final double width;

  /// Bardak yüksekliği
  final double height;

  const AnimatedWaterGlass({
    super.key,
    required this.progress,
    this.width = 88,
    this.height = 120,
  });

  @override
  State<AnimatedWaterGlass> createState() => _AnimatedWaterGlassState();
}

class _AnimatedWaterGlassState extends State<AnimatedWaterGlass>
    with TickerProviderStateMixin {
  // ── Animasyon Controller'ları ──────────────────────────────────────────
  /// Dalga animasyonu — sürekli tekrar
  late final AnimationController _waveController;

  /// Baloncuk animasyonu — sürekli tekrar
  late final AnimationController _bubbleController;

  /// Dolum animasyonu — progress değişiminde tetiklenir
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;

  double _previousProgress = 0.0;

  // ── Baloncuk verileri ─────────────────────────────────────────────────
  late final List<_BubbleData> _bubbles;

  // ── Sabitler ──────────────────────────────────────────────────────────
  static const _waveDuration = Duration(milliseconds: 4000);
  static const _bubbleDuration = Duration(milliseconds: 5000);
  static const _fillDuration = Duration(milliseconds: 800);

  static const _waterColorDeep = Color(0xFF1A8FD1);
  static const _waterColorLight = Color(0xFF26B0EF);
  static const _waterColorSurface = Color(0xFF7DD3FC);

  @override
  void initState() {
    super.initState();

    // Dalga — sürekli döngü
    _waveController = AnimationController(vsync: this, duration: _waveDuration)
      ..repeat();

    // Baloncuk — sürekli döngü
    _bubbleController =
        AnimationController(vsync: this, duration: _bubbleDuration)..repeat();

    // Dolum animasyonu
    _fillController =
        AnimationController(vsync: this, duration: _fillDuration);
    _fillAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic,
    ));
    _fillController.forward();

    // Baloncukları oluştur
    final rng = math.Random(42);
    _bubbles = List.generate(5, (i) {
      return _BubbleData(
        xFraction: 0.15 + rng.nextDouble() * 0.7, // 0.15–0.85 arası yatay konum
        size: 3.0 + rng.nextDouble() * 4.0,       // 3–7px arası boyut
        speed: 0.6 + rng.nextDouble() * 0.4,       // 0.6–1.0 arası hız çarpanı
        phaseOffset: i * 0.2,                       // Stagger offset
        opacity: 0.25 + rng.nextDouble() * 0.35,    // 0.25–0.6 arası opaklık
      );
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedWaterGlass oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.progress != widget.progress) {
      _previousProgress = _fillAnimation.value;
      _fillAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutCubic,
      ));
      _fillController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bubbleController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspektif
        ..rotateY(0.04)         // Hafif sağa dönük
        ..rotateX(-0.015),      // Hafif yukarı eğik
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _fillController, _bubbleController]),
        builder: (context, child) {
          final fillValue = _fillAnimation.value.clamp(0.0, 1.0);
          final wavePhase = _waveController.value * 2 * math.pi;
          final bubblePhase = _bubbleController.value;

          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // Glow aura — su seviyesine göre yoğunlaşır
              boxShadow: [
                BoxShadow(
                  color: _waterColorLight.withValues(alpha: 0.15 + fillValue * 0.2),
                  blurRadius: 12 + fillValue * 8,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // 1. Arka plan — yarı saydam cam
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  // 2. Su dolum + dalga
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WavePainter(
                        fillLevel: fillValue,
                        wavePhase: wavePhase,
                        deepColor: _waterColorDeep,
                        lightColor: _waterColorLight,
                        surfaceColor: _waterColorSurface,
                      ),
                    ),
                  ),

                  // 3. Baloncuklar
                  ..._buildBubbles(fillValue, bubblePhase),

                  // 4. Cam yansıması — çapraz parlama
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: const Alignment(-0.8, -1.0),
                            end: const Alignment(0.8, 1.0),
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.08),
                            ],
                            stops: const [0.0, 0.35, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 5. Sol kenar ince parlama şeridi
                  Positioned(
                    left: 6,
                    top: 12,
                    bottom: 12,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.4),
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 6. Yüzde etiketi
                  Center(
                    child: TweenAnimationBuilder<int>(
                      tween: IntTween(
                        begin: (_previousProgress * 100).round(),
                        end: (widget.progress * 100).round(),
                      ),
                      duration: _fillDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        final isFilled = fillValue > 0.5;
                        return Text(
                          '%$value',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isFilled
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
                            shadows: isFilled
                                ? [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Baloncuk widget'larını oluşturur.
  List<Widget> _buildBubbles(double fillLevel, double bubblePhase) {
    if (fillLevel < 0.05) return []; // Su çok azsa baloncuk yok

    return _bubbles.map((bubble) {
      // Her baloncuğun kendi fazı (stagger)
      final phase = (bubblePhase + bubble.phaseOffset) % 1.0;
      // Baloncuk sadece su içinde görünür
      final waterTop = widget.height * (1.0 - fillLevel);
      final bubbleBottom = widget.height; // Dipten başlar
      final travelRange = bubbleBottom - waterTop;
      // Baloncuk konumu: dipten yüzeye doğru
      final yPos = bubbleBottom - (phase * travelRange * bubble.speed);

      // Yüzeyin üstüne çıkmışsa gizle
      if (yPos < waterTop) return const SizedBox.shrink();

      // Yüzeye yaklaştıkça soluklaş
      final distToSurface = (yPos - waterTop) / travelRange;
      final opacity = bubble.opacity * distToSurface.clamp(0.2, 1.0);

      return Positioned(
        left: widget.width * bubble.xFraction - bubble.size / 2,
        top: yPos - bubble.size / 2,
        child: Container(
          width: bubble.size,
          height: bubble.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: opacity * 0.5),
              width: 0.5,
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Dalga CustomPainter
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _WavePainter extends CustomPainter {
  final double fillLevel;  // 0.0–1.0
  final double wavePhase;  // radyan (0–2π)
  final Color deepColor;
  final Color lightColor;
  final Color surfaceColor;

  /// Dalga yüksekliği (piksel)
  static const double _waveAmplitude = 3.0;

  /// Dalga frekansı
  static const double _waveFrequency = 1.5;

  _WavePainter({
    required this.fillLevel,
    required this.wavePhase,
    required this.deepColor,
    required this.lightColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel <= 0) return;

    final waterTop = size.height * (1.0 - fillLevel);

    // ── 1. Arka dalga (hafif, daha yavaş, farklı faz) ─────────────────────
    _drawWave(
      canvas,
      size,
      waterTop: waterTop,
      phase: wavePhase * 0.6 + math.pi * 0.7, // Belirgin faz farkı
      amplitude: _waveAmplitude * 0.55,
      frequency: _waveFrequency * 1.2,
      color: lightColor.withValues(alpha: 0.45),
    );

    // ── 2. Ana dalga (belirgin) ──────────────────────────────────────────
    _drawWave(
      canvas,
      size,
      waterTop: waterTop,
      phase: wavePhase,
      amplitude: _waveAmplitude,
      frequency: _waveFrequency,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          surfaceColor.withValues(alpha: 0.7),
          lightColor.withValues(alpha: 0.8),
          deepColor.withValues(alpha: 0.85),
        ],
        stops: const [0.0, 0.4, 1.0],
      ),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double waterTop,
    required double phase,
    required double amplitude,
    required double frequency,
    Color? color,
    Gradient? gradient,
  }) {
    final path = Path();

    // Dalga yüzeyi çiz — 0.5px adımla smooth path
    path.moveTo(0, waterTop + math.sin(phase) * amplitude);
    for (double x = 0.5; x <= size.width; x += 0.5) {
      final normalizedX = x / size.width;
      final y = waterTop +
          math.sin(normalizedX * frequency * 2 * math.pi + phase) * amplitude;
      path.lineTo(x, y);
    }

    // Alt köşelere bağla (kapalı şekil)
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    if (gradient != null) {
      final rect = Rect.fromLTWH(0, waterTop, size.width, size.height - waterTop);
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    } else if (color != null) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel ||
        oldDelegate.wavePhase != wavePhase;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Baloncuk veri modeli
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _BubbleData {
  /// Yatay konum (0.0–1.0 — bardak genişliğinin yüzdesi)
  final double xFraction;

  /// Baloncuk boyutu (piksel)
  final double size;

  /// Hız çarpanı (0.0–1.0)
  final double speed;

  /// Stagger animasyon fazı (0.0–1.0)
  final double phaseOffset;

  /// Opaklık (0.0–1.0)
  final double opacity;

  const _BubbleData({
    required this.xFraction,
    required this.size,
    required this.speed,
    required this.phaseOffset,
    required this.opacity,
  });
}
