import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../providers/follow_up_dashboard_provider.dart';

/// Dashboard üst kısmındaki özet kartları widget'ı.
class FollowUpSummaryCards extends StatelessWidget {
  final FollowUpDashboardProvider provider;
  final ValueChanged<FollowUpFilter> onFilterTap;

  const FollowUpSummaryCards({
    super.key,
    required this.provider,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _SummaryCard(
            icon: Icons.warning_amber_rounded,
            label: 'Gecikmiş',
            count: provider.overdueCount,
            color: AppColors.error,
            isActive: provider.activeFilter == FollowUpFilter.overdue,
            onTap: () => onFilterTap(FollowUpFilter.overdue),
          ),
          const SizedBox(width: 10),
          _SummaryCard(
            icon: Icons.today,
            label: 'Bugün',
            count: provider.todayCount,
            color: AppColors.accent,
            isActive: provider.activeFilter == FollowUpFilter.today,
            onTap: () => onFilterTap(FollowUpFilter.today),
          ),
          const SizedBox(width: 10),
          _SummaryCard(
            icon: Icons.date_range,
            label: 'Bu Hafta',
            count: provider.thisWeekCount,
            color: AppColors.primary,
            isActive: provider.activeFilter == FollowUpFilter.thisWeek,
            onTap: () => onFilterTap(FollowUpFilter.thisWeek),
          ),
          const SizedBox(width: 10),
          _SummaryCard(
            icon: Icons.check_circle_outline,
            label: 'Tamamlanan',
            count: provider.completedCount,
            color: AppColors.secondary,
            isActive: provider.activeFilter == FollowUpFilter.completed,
            onTap: () => onFilterTap(FollowUpFilter.completed),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withAlpha(25) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : AppColors.textMutedLighter,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? color : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
