import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';

/// Müşteri için Kompakt Başarı Gösterge Kartı.
/// Yatay düzende (Row) sol tarafta halka, sağ tarafta 3 durum kapsülü yer alır.
class DailyCompactSuccessCard extends StatefulWidget {
  final double productProgress;
  final double waterProgress;
  final double exerciseProgress;

  const DailyCompactSuccessCard({
    super.key,
    required this.productProgress,
    required this.waterProgress,
    required this.exerciseProgress,
  });

  @override
  State<DailyCompactSuccessCard> createState() => _DailyCompactSuccessCardState();
}

class _DailyCompactSuccessCardState extends State<DailyCompactSuccessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animCurve;

  double _prevProduct = 0;
  double _prevWater = 0;
  double _prevExercise = 0;

  static const _entryDuration = Duration(milliseconds: 1000);
  static const _productColor = Color(0xFF22C55E);
  static const _waterColor = Color(0xFF26B0EF);
  static const _exerciseColor = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: _entryDuration);
    _animCurve = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant DailyCompactSuccessCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productProgress != widget.productProgress ||
        oldWidget.waterProgress != widget.waterProgress ||
        oldWidget.exerciseProgress != widget.exerciseProgress) {
      _prevProduct = oldWidget.productProgress;
      _prevWater = oldWidget.waterProgress;
      _prevExercise = oldWidget.exerciseProgress;
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEBF7E3), // Soft fıstık yeşili
            Color(0xFFEFF6FF), // Soft mavi
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sol: 3 Dilimli Başarı Halkası
          Expanded(
            flex: 4,
            child: AnimatedBuilder(
              animation: _animCurve,
              builder: (context, child) {
                final t = _animCurve.value;
                final pProg = _lerpProgress(_prevProduct, widget.productProgress, t);
                final wProg = _lerpProgress(_prevWater, widget.waterProgress, t);
                final eProg = _lerpProgress(_prevExercise, widget.exerciseProgress, t);
                final displayPct = (((pProg + wProg + eProg) / 3.0).clamp(0.0, 1.0) * 100).round();

                return Center(
                  child: SizedBox(
                    width: 105,
                    height: 105,
                    child: CustomPaint(
                      painter: _CompactSuccessRingPainter(
                        productProgress: pProg,
                        waterProgress: wProg,
                        exerciseProgress: eProg,
                        strokeWidth: 9.0,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '%$displayPct',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.nightSky,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'TAMAMLANDI',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Sağ: Kapsüller (Durum Göstergeleri)
          Expanded(
            flex: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusCapsule('ÜRÜN', widget.productProgress, _productColor),
                const SizedBox(height: 8),
                _buildStatusCapsule('SU', widget.waterProgress, _waterColor),
                const SizedBox(height: 8),
                _buildStatusCapsule('EGZERSİZ', widget.exerciseProgress, _exerciseColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCapsule(String label, double progress, Color dotColor) {
    final pct = (progress * 100).round();
    final fillColor = dotColor.withAlpha(30);
    final displayColor = Color.lerp(dotColor, Colors.black, 0.25) ?? dotColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Dolgu İlerlemesi (Progress fill)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          fillColor,
                          fillColor.withAlpha(15),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Kapsül İçeriği
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: displayColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    '%$pct',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: displayColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _lerpProgress(double from, double to, double t) {
    return from + (to - from) * t;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CustomPainter — 3 dilimli kompakt halka çizimi
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CompactSuccessRingPainter extends CustomPainter {
  final double productProgress;
  final double waterProgress;
  final double exerciseProgress;
  final double strokeWidth;

  static const double _gapAngle = 0.08;

  static double get _segmentAngle =>
      (2 * math.pi - 3 * _gapAngle) / 3;

  static const _productColor = Color(0xFF22C55E);
  static const _waterColor = Color(0xFF26B0EF);
  static const _exerciseColor = Color(0xFFF97316);
  static const _bgColor = Color(0xFFE2E8F0); // slate-200

  _CompactSuccessRingPainter({
    required this.productProgress,
    required this.waterProgress,
    required this.exerciseProgress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = _bgColor;

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startOffset = -math.pi / 2;

    // 1. Dilim: Ürün (Yeşil)
    final seg1Start = startOffset;
    _drawSegment(
      canvas, rect, bgPaint, fgPaint,
      startAngle: seg1Start,
      progress: productProgress,
      color: _productColor,
    );

    // 2. Dilim: Su (Mavi)
    final seg2Start = seg1Start + _segmentAngle + _gapAngle;
    _drawSegment(
      canvas, rect, bgPaint, fgPaint,
      startAngle: seg2Start,
      progress: waterProgress,
      color: _waterColor,
    );

    // 3. Dilim: Egzersiz (Turuncu)
    final seg3Start = seg2Start + _segmentAngle + _gapAngle;
    _drawSegment(
      canvas, rect, bgPaint, fgPaint,
      startAngle: seg3Start,
      progress: exerciseProgress,
      color: _exerciseColor,
    );
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
    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    if (progress > 0) {
      fgPaint.color = color;
      final fillAngle = sweepAngle * progress.clamp(0.0, 1.0);
      canvas.drawArc(rect, startAngle, fillAngle, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompactSuccessRingPainter oldDelegate) {
    return oldDelegate.productProgress != productProgress ||
        oldDelegate.waterProgress != waterProgress ||
        oldDelegate.exerciseProgress != exerciseProgress;
  }
}
