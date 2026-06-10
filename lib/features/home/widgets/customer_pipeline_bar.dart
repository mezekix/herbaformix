import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

/// Müşteri portföyünün şeklini tek bakışta gösteren 4 segment chip.
///
///   Yeni  →  Aktif  →  Risk Altı  →  Pasif
///
/// Yeni + Aktif + Pasif overlap'siz, toplamı toplam müşteri sayısına
/// eşit. "Risk Altı" Aktif'in alt kümesidir (insights servisinden
/// async olarak geldiği için ayrı segment).
class CustomerPipelineBar extends StatelessWidget {
  final int newCount;
  final int activeCount;
  final int? riskCount; // null → yükleniyor
  final int passiveCount;
  final VoidCallback? onNewTap;
  final VoidCallback? onActiveTap;
  final VoidCallback? onRiskTap;
  final VoidCallback? onPassiveTap;

  const CustomerPipelineBar({
    super.key,
    required this.newCount,
    required this.activeCount,
    required this.riskCount,
    required this.passiveCount,
    this.onNewTap,
    this.onActiveTap,
    this.onRiskTap,
    this.onPassiveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              'MÜŞTERİ PORTFÖYÜ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _PipelineSegment(
                  label: 'Yeni',
                  count: newCount,
                  color: AppColors.primary,
                  onTap: onNewTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PipelineSegment(
                  label: 'Aktif',
                  count: activeCount,
                  color: AppColors.lake,
                  onTap: onActiveTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PipelineSegment(
                  label: 'Risk Altı',
                  count: riskCount,
                  color: AppColors.papaya,
                  emphasized: (riskCount ?? 0) > 0,
                  onTap: onRiskTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PipelineSegment(
                  label: 'Pasif',
                  count: passiveCount,
                  color: Colors.grey.shade500,
                  onTap: onPassiveTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipelineSegment extends StatelessWidget {
  final String label;
  final int? count;
  final Color color;
  final bool emphasized;
  final VoidCallback? onTap;

  const _PipelineSegment({
    required this.label,
    required this.count,
    required this.color,
    this.emphasized = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = count == null;
    final isEmpty = (count ?? 0) == 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: emphasized ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: emphasized
                  ? color.withValues(alpha: 0.4)
                  : Colors.grey.shade200,
              width: emphasized ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst renk şeridi — segment kimliği
              Container(
                width: 22,
                height: 3,
                decoration: BoxDecoration(
                  color: isLoading || isEmpty
                      ? color.withValues(alpha: 0.3)
                      : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              isLoading
                  ? SizedBox(
                      height: 22,
                      child: Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: color.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    )
                  : Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: isEmpty
                            ? Colors.grey.shade400
                            : AppColors.nightSky,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: emphasized ? color : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
