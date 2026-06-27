import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

/// Distribütör dashboard'unun "kalbi": Aylık VP hedefinin tek bakışta
/// görüldüğü hero kart. Sol tarafta dairesel gauge, sağda tempo metrikleri.
///
/// 3D derinlik efektleri: çok katmanlı gölgeler, gradient arka plan,
/// parlak gauge efekti ve glassmorphism dokunuşları.
///
/// Renk durumu:
///   - Hedefte / önünde   → AppColors.grass     (yeşil)
///   - Sınırda            → AppColors.mangoDeep (amber — kontrast uyumlu)
///   - Yavaş / riskte     → AppColors.papaya    (kırmızı)
class VpPulseCard extends StatelessWidget {
  final double vpEarned;
  final int vpTarget;
  final VoidCallback? onTap;
  final VoidCallback? onSetTarget;

  const VpPulseCard({
    super.key,
    required this.vpEarned,
    required this.vpTarget,
    this.onTap,
    this.onSetTarget,
  });

  /// Progress değerine göre gauge uç rengini hesapla (container shadow için).
  static Color _gaugeEndColor(double progress) {
    const greenStart = Color(0xFFB9E4A7);
    const greenMid = Color(0xFF7AC144);
    const greenEnd = Color(0xFF266431);
    if (progress <= 0.5) {
      return Color.lerp(greenStart, greenMid, (progress / 0.5).clamp(0.0, 1.0))!;
    }
    return Color.lerp(greenMid, greenEnd, ((progress - 0.5) / 0.5).clamp(0.0, 1.0))!;
  }

  @override
  Widget build(BuildContext context) {
    if (vpTarget <= 0) {
      return _buildNoTargetCard(context);
    }

    final now = DateTime.now();
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysSoFar = now.day;
    final daysLeft = math.max(0, totalDaysInMonth - daysSoFar);

    final progress = (vpEarned / vpTarget).clamp(0.0, 1.0);
    final expectedSoFar = vpTarget * (daysSoFar / totalDaysInMonth);
    final paceRatio = expectedSoFar > 0 ? vpEarned / expectedSoFar : 0.0;

    final remainingVp = math.max(0.0, vpTarget - vpEarned);
    final dailyNeeded = daysLeft > 0
        ? (remainingVp / daysLeft).ceil()
        : remainingVp.ceil();

    final status = _resolveStatus(paceRatio, progress);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              // 3D gradient arka plan
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF8FAF6),
                  Color(0xFFF0F5EC),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              // İç parlama efekti için border
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
              // Çok katmanlı 3D gölgeler
              boxShadow: [
                // Ana derin gölge
                BoxShadow(
                  color: const Color(0xFF266431).withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
                // Orta mesafe gölge
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 5),
                ),
                // Yakın keskin gölge
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
                // Üst kenar iç ışık efekti (beyaz gölge yukarı)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: -2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 3D Gauge container — hafif gölge ile çökmüş efekt
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Gauge arkasında yeşil tonlu inset gölge efekti
                    boxShadow: [
                      BoxShadow(
                        color: _gaugeEndColor(progress).withValues(alpha: 0.15),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.7),
                        blurRadius: 8,
                        spreadRadius: -2,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _VpGaugePainter3D(
                      progress: progress,
                      track: AppColors.background,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Yüzde rakamı — gölge efektli
                          Text(
                            '%${(progress * 100).round()}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.nightSky,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: status.color.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TAMAM',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Başlık — gradient efektli
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF3A5137),
                            Color(0xFF266431),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'AYLIK HEDEF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // VP değerleri
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _formatVp(vpEarned),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.nightSky,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: ' / ${_formatVp(vpTarget.toDouble())} VP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _StatusChip3D(status: status),
                      const SizedBox(height: 10),
                      // Meta bilgiler — cam efektli arka plan
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Column(
                          children: [
                            _MetaRow(
                              icon: Icons.calendar_today_outlined,
                              text: daysLeft > 0
                                  ? 'Ay sonuna $daysLeft gün'
                                  : 'Bugün ayın son günü',
                            ),
                            const SizedBox(height: 5),
                            _MetaRow(
                              icon: Icons.bolt_outlined,
                              text: progress >= 1.0
                                  ? 'Hedefe ulaştın 🎉'
                                  : 'Günde gereken: $dailyNeeded VP',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoTargetCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onSetTarget,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.primary.withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.06),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flag_outlined,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aylık VP hedefini belirle',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.nightSky,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tempoyu ve günlük hedefini buradan takip edebilirsin.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios,
                      size: 13, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _PaceStatus _resolveStatus(double paceRatio, double progress) {
    if (progress >= 1.0) {
      return const _PaceStatus(
        label: 'Hedefe ulaşıldı',
        color: AppColors.grass,
        icon: Icons.emoji_events_outlined,
      );
    }
    if (paceRatio >= 1.0) {
      return const _PaceStatus(
        label: 'Hedefin önündesin',
        color: AppColors.grass,
        icon: Icons.trending_up,
      );
    }
    if (paceRatio >= 0.85) {
      return const _PaceStatus(
        label: 'Tempo sınırda',
        color: AppColors.mangoDeep,
        icon: Icons.schedule,
      );
    }
    return const _PaceStatus(
      label: 'Tempon yavaş',
      color: AppColors.papaya,
      icon: Icons.warning_amber_rounded,
    );
  }

  String _formatVp(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 1 : 2)}K';
    }
    return v.toStringAsFixed(0);
  }
}

class _PaceStatus {
  final String label;
  final Color color;
  final IconData icon;

  const _PaceStatus({
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// 3D efektli status chip — glassmorphism dokunuşuyla
class _StatusChip3D extends StatelessWidget {
  final _PaceStatus status;
  const _StatusChip3D({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            status.color.withValues(alpha: 0.15),
            status.color.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: status.color.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: 14),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 3D efektli dairesel VP gauge — yeşil tonlarında açık→koyu gradient.
///
/// Katmanlar:
///   1. Dış gölge halkası (derinlik hissi)
///   2. Track halkası (arka plan yolu)
///   3. Progress arc'ı (açık yeşil → koyu yeşil SweepGradient + gölge)
///   4. Uç noktada parlak nokta (highlight dot)
class _VpGaugePainter3D extends CustomPainter {
  final double progress;
  final Color track;

  // Yeşil skalası: en açık → en koyu
  static const _greenStart = Color(0xFFB9E4A7); // Çok açık yeşil
  static const _greenMid   = Color(0xFF7AC144); // Canlı yeşil (primary)
  static const _greenEnd   = Color(0xFF266431); // Koyu yeşil (garden)

  _VpGaugePainter3D({
    required this.progress,
    required this.track,
  });

  /// Progress değerine göre uç rengi hesapla (glow ve dot için).
  Color _endColorForProgress(double p) {
    if (p <= 0.5) {
      return Color.lerp(_greenStart, _greenMid, (p / 0.5).clamp(0.0, 1.0))!;
    }
    return Color.lerp(_greenMid, _greenEnd, ((p - 0.5) / 0.5).clamp(0.0, 1.0))!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Dış gölge halkası — 3D derinlik efekti
    final outerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, radius, outerShadowPaint);

    // 2. Track (arka plan yolu) — hafif iç gölge efekti
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Çökmüş iç kenar efekti — üstten koyu gölge
    final innerShadowDarkPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke - 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawArc(
      rect,
      -math.pi * 0.7,
      math.pi * 0.4,
      false,
      innerShadowDarkPaint,
    );

    // Çökmüş iç kenar efekti — alttan parlak
    final innerShadowLightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke - 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawArc(
      rect,
      math.pi * 0.3,
      math.pi * 0.4,
      false,
      innerShadowLightPaint,
    );

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    final endColor = _endColorForProgress(progress);

    // 3. Progress arc gölgesi — arkada yumuşak yeşil glow
    final arcShadowPaint = Paint()
      ..color = endColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcShadowPaint);

    // 4. Progress arc — açık yeşilden koyu yeşile SweepGradient
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    progressPaint.shader = SweepGradient(
      startAngle: 0,
      endAngle: sweep,
      colors: [
        _greenStart,
        _greenMid,
        endColor,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);

    // 5. Progress arc üzerinde parlak highlight çizgisi
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.35
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke * 0.15),
      -math.pi / 2,
      sweep,
      false,
      highlightPaint,
    );

    // 6. Uç noktada parlak dot (highlight) — 3D boncuk efekti
    if (progress > 0.02) {
      final endAngle = -math.pi / 2 + sweep;
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);
      final dotCenter = Offset(dotX, dotY);

      // Dot gölgesi
      final dotShadow = Paint()
        ..color = endColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        dotCenter + const Offset(0, 1),
        stroke * 0.45,
        dotShadow,
      );

      // Dot ana renk — radial gradient
      final dotPaint = Paint()
        ..shader = ui.Gradient.radial(
          dotCenter - const Offset(1.5, 1.5),
          stroke * 0.5,
          [
            _lightenColor(endColor, 0.25),
            endColor,
          ],
        );
      canvas.drawCircle(dotCenter, stroke * 0.45, dotPaint);

      // Dot parlak nokta (specular highlight)
      final specPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7);
      canvas.drawCircle(
        dotCenter - const Offset(1.5, 1.5),
        stroke * 0.15,
        specPaint,
      );
    }
  }

  Color _lightenColor(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _VpGaugePainter3D old) =>
      old.progress != progress || old.track != track;
}
