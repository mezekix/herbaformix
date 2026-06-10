import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

/// Dashboard'un "Bugün ne yapmalıyım?" sorusunu cevaplayan 3'lü chip
/// satırı. Her chip eylem odaklı: tıklayınca ilgili göreve götürür.
///
/// Sıralama dikkatli: "Bugün" → gündelik tempo, "Gecikmiş" → uyarı,
/// "Bekleyen Sipariş" → operasyonel iş.
class TodayActionsStrip extends StatelessWidget {
  final int dueTodayCount;
  final int overdueCount;
  final int pendingOrdersCount;
  final VoidCallback? onDueTodayTap;
  final VoidCallback? onOverdueTap;
  final VoidCallback? onPendingOrdersTap;

  const TodayActionsStrip({
    super.key,
    required this.dueTodayCount,
    required this.overdueCount,
    required this.pendingOrdersCount,
    this.onDueTodayTap,
    this.onOverdueTap,
    this.onPendingOrdersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.today_outlined,
              count: dueTodayCount,
              label: 'Bugün',
              color: AppColors.primary,
              onTap: onDueTodayTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionChip(
              icon: Icons.warning_amber_rounded,
              count: overdueCount,
              label: 'Gecikmiş',
              color: AppColors.papaya,
              onTap: onOverdueTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionChip(
              icon: Icons.receipt_long_outlined,
              count: pendingOrdersCount,
              label: 'Sipariş',
              color: AppColors.laguna,
              onTap: onPendingOrdersTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasItems = count > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasItems
                  ? color.withValues(alpha: 0.35)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: hasItems
                      ? color.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: hasItems ? color : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: hasItems
                            ? AppColors.nightSky
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
