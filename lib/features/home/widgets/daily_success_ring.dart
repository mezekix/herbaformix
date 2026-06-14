import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Günlük Başarı Halkası — 3 dilimli dairesel ilerleme göstergesi.
///
/// Dilimler:
///   • Ürün  (yeşil)  — Tamamlanan ürün/yemek rutinleri oranı
///   • Su    (mavi)   — Su tüketim oranı
///   • Egzersiz (turuncu) — Egzersiz tamamlanma durumu
///
/// Animasyonlar:
///   • Sayfa açılışında 0→mevcut değere 1s akıcı dolma
///   • %100 olunca halka parlaması + konfeti
class DailySuccessRing extends StatefulWidget {
  /// Ürün rutinleri ilerleme oranı (0.0–1.0)
  final double productProgress;

  /// Su tüketimi ilerleme oranı (0.0–1.0)
  final double waterProgress;

  /// Egzersiz ilerleme oranı (0.0 veya 1.0)
  final double exerciseProgress;

  /// Halkanın ortasında gösterilecek aktif görev metni
  final String activeTaskLabel;

  /// Program var mı — yoksa teşvik kartı gösterilir
  final bool hasProgram;

  /// "Program Oluştur" tıklaması
  final VoidCallback? onCreateProgram;

  /// Halka boyutu (genişlik & yükseklik)
  final double size;

  const DailySuccessRing({
    super.key,
    required this.productProgress,
    required this.waterProgress,
    required this.exerciseProgress,
    this.activeTaskLabel = '',
    this.hasProgram = true,
    this.onCreateProgram,
    this.size = 220,
  });

  @override
  State<DailySuccessRing> createState() => _DailySuccessRingState();
}

class _DailySuccessRingState extends State<DailySuccessRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animCurve;
  late ConfettiController _confettiController;

  /// Önceki değerler — pop efekti için karşılaştırma
  double _prevProduct = 0;
  double _prevWater = 0;
  double _prevExercise = 0;
  bool _hasPlayedConfetti = false;

  // ── Sabitler ────────────────────────────────────────────────────────────
  static const _entryDuration = Duration(milliseconds: 1000);
  static const _productColor = Color(0xFF22C55E);
  static const _waterColor = Color(0xFF3B82F6);
  static const _exerciseColor = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: _entryDuration);
    _animCurve = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // İlk açılışta 0'dan dolma animasyonu
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant DailySuccessRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Değer değiştiğinde tekrar animasyon tetikle
    if (oldWidget.productProgress != widget.productProgress ||
        oldWidget.waterProgress != widget.waterProgress ||
        oldWidget.exerciseProgress != widget.exerciseProgress) {
      _prevProduct = oldWidget.productProgress;
      _prevWater = oldWidget.waterProgress;
      _prevExercise = oldWidget.exerciseProgress;

      _animController.forward(from: 0);
    }

    // %100 olunca konfeti patla (sadece bir kez)
    final total = _overallProgress;
    if (total >= 1.0 && !_hasPlayedConfetti) {
      _hasPlayedConfetti = true;
      _confettiController.play();
    } else if (total < 1.0) {
      _hasPlayedConfetti = false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  /// 3 dilimin ağırlıklı ortalaması
  double get _overallProgress {
    return ((widget.productProgress + widget.waterProgress + widget.exerciseProgress) / 3.0)
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasProgram) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Konfeti widget'ı — halkanın üstünden patlar
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 25,
            maxBlastForce: 15,
            minBlastForce: 5,
            emissionFrequency: 0.06,
            gravity: 0.15,
            colors: const [
              _productColor,
              _waterColor,
              _exerciseColor,
              Color(0xFFFBBF24), // altın
              Color(0xFFA855F7), // mor
            ],
          ),
        ),

        // Ana halka
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animCurve,
              builder: (context, child) {
                final t = _animCurve.value;
                // Lerp: önceki değerlerden yeni değerlere geçiş
                final pProg = _lerpProgress(_prevProduct, widget.productProgress, t);
                final wProg = _lerpProgress(_prevWater, widget.waterProgress, t);
                final eProg = _lerpProgress(_prevExercise, widget.exerciseProgress, t);

                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _SuccessRingPainter(
                      productProgress: pProg,
                      waterProgress: wProg,
                      exerciseProgress: eProg,
                      isComplete: _overallProgress >= 1.0 && t >= 0.95,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Büyük yüzde
                          Text(
                            '%${(((pProg + wProg + eProg) / 3.0).clamp(0.0, 1.0) * 100).round()}',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF101820),
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TAMAMLANDI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (widget.activeTaskLabel.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                widget.activeTaskLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Dilim açıklamaları (legend)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Ürün', _productColor, widget.productProgress),
                const SizedBox(width: 20),
                _buildLegendItem('Su', _waterColor, widget.waterProgress),
                const SizedBox(width: 20),
                _buildLegendItem('Egzersiz', _exerciseColor, widget.exerciseProgress),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, double progress) {
    final pct = (progress * 100).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label %$pct',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  double _lerpProgress(double from, double to, double t) {
    return from + (to - from) * t;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CustomPainter — 3 dilimli halka çizimi
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SuccessRingPainter extends CustomPainter {
  final double productProgress;
  final double waterProgress;
  final double exerciseProgress;
  final bool isComplete;

  /// Halka kalınlığı
  static const double _strokeWidth = 16.0;

  /// Dilimler arası boşluk (radyan)
  static const double _gapAngle = 0.06;

  /// Her dilimin toplam açısı (3 eşit dilim − 3 boşluk)
  static double get _segmentAngle =>
      (2 * math.pi - 3 * _gapAngle) / 3;

  // Renk sabitleri
  static const _productColor = Color(0xFF22C55E);
  static const _waterColor = Color(0xFF3B82F6);
  static const _exerciseColor = Color(0xFFF97316);

  static const _bgColor = Color(0xFFF1F5F9);

  _SuccessRingPainter({
    required this.productProgress,
    required this.waterProgress,
    required this.exerciseProgress,
    this.isComplete = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = _bgColor;

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    // Başlangıç açısı: 12 o'clock konumu (−π/2)
    const startOffset = -math.pi / 2;

    // ── Dilim 1: Ürün (Yeşil) ──────────────────────────────────────────
    final seg1Start = startOffset;
    _drawSegment(
      canvas, rect, bgPaint, fgPaint,
      startAngle: seg1Start,
      progress: productProgress,
      color: _productColor,
    );

    // ── Dilim 2: Su (Mavi) ─────────────────────────────────────────────
    final seg2Start = seg1Start + _segmentAngle + _gapAngle;
    _drawSegment(
      canvas, rect, bgPaint, fgPaint,
      startAngle: seg2Start,
      progress: waterProgress,
      color: _waterColor,
    );

    // ── Dilim 3: Egzersiz (Turuncu) ────────────────────────────────────
    final seg3Start = seg2Start + _segmentAngle + _gapAngle;
    _drawSegment(
      canvas, rect, bgPaint, fgPaint,
      startAngle: seg3Start,
      progress: exerciseProgress,
      color: _exerciseColor,
    );

    // ── %100 Glow Efekti ───────────────────────────────────────────────
    if (isComplete) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth + 6
        ..color = const Color(0xFF22C55E).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, radius, glowPaint);
    }
  }

  void _drawSegment(
    Canvas canvas,
    Rect rect,
    Paint bgPaint,
    Paint fgPaint, {
    required double startAngle,
    required double progress,
    required Color color,
  }) {
    final sweepAngle = _segmentAngle;

    // Arka plan yayı
    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    // Ön plan dolum yayı
    if (progress > 0) {
      fgPaint.color = color;
      final fillAngle = sweepAngle * progress.clamp(0.0, 1.0);
      canvas.drawArc(rect, startAngle, fillAngle, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessRingPainter oldDelegate) {
    return oldDelegate.productProgress != productProgress ||
        oldDelegate.waterProgress != waterProgress ||
        oldDelegate.exerciseProgress != exerciseProgress ||
        oldDelegate.isComplete != isComplete;
  }
}
