import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

/// Distribütör dashboard'unun "kalbi": Aylık VP hedefinin tek bakışta
/// görüldüğü hero kart. Sol tarafta dairesel gauge, sağda tempo metrikleri.
///
/// Renk durumu:
///   - Hedefte / önünde   → AppColors.grass   (yeşil)
///   - Sınırda            → AppColors.mango   (amber)
///   - Yavaş / riskte     → AppColors.papaya  (kırmızı)
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 116,
                  height: 116,
                  child: CustomPaint(
                    painter: _VpGaugePainter(
                      progress: progress,
                      color: status.color,
                      track: AppColors.background,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '%${(progress * 100).round()}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.nightSky,
                              height: 1.1,
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'AYLIK HEDEF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _formatVp(vpEarned),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.nightSky,
                                height: 1.1,
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
                      _StatusChip(status: status),
                      const SizedBox(height: 10),
                      _MetaRow(
                        icon: Icons.calendar_today_outlined,
                        text: daysLeft > 0
                            ? 'Ay sonuna $daysLeft gün'
                            : 'Bugün ayın son günü',
                      ),
                      const SizedBox(height: 4),
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
        ),
      ),
    );
  }

  Widget _buildNoTargetCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onSetTarget,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
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
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.primary),
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
        color: AppColors.mango,
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

class _StatusChip extends StatelessWidget {
  final _PaceStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: 13),
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

class _VpGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _VpGaugePainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VpGaugePainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
