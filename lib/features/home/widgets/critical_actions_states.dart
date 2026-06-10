import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

/// Kritik Aksiyonlar listesi boş olduğunda gösterilen "tebrik" durumu.
/// Düz text yerine kart + ikon — dashboard'un geri kalanıyla tutarlı.
class CriticalActionsEmptyState extends StatelessWidget {
  const CriticalActionsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.rain.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lake.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.lake.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.lake,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugün takvimin temiz 🎯',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.nightSky,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Bekleyen takip yok. Yeni müşteriye ulaşmak için iyi bir an.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                      height: 1.3,
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
}

/// Kritik Aksiyonlar verisi yüklenirken gösterilen pulse'lu skeleton.
/// 2 placeholder kart — gerçek satır yüksekliğine yakın, kullanıcının
/// kaç tane bekleyeceği konusunda fikir vermez ama "bir şey geliyor"
/// hissi verir.
class CriticalActionsSkeleton extends StatelessWidget {
  const CriticalActionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: const [
          _SkeletonCard(),
          SizedBox(height: 12),
          _SkeletonCard(),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _PulseBox(width: 40, height: 40, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _PulseBox(width: 140, height: 12, radius: 4),
                    SizedBox(height: 8),
                    _PulseBox(width: 90, height: 10, radius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _PulseBox(height: 32, radius: 10)),
              SizedBox(width: 6),
              Expanded(child: _PulseBox(height: 32, radius: 10)),
              SizedBox(width: 6),
              Expanded(child: _PulseBox(height: 32, radius: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Düşük-overhead pulse animasyon kutusu. Shimmer paketi olmadan, basit
/// AnimationController ile opaklık 0.5–1.0 arasında nefes alır.
class _PulseBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const _PulseBox({
    this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  State<_PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<_PulseBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = 0.55 + (_ctrl.value * 0.35); // 0.55 → 0.90
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.grey.shade100,
              Colors.grey.shade300,
              t,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
