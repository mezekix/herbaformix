import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/badge_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../progress/providers/progress_provider.dart';
import '../../progress/screens/measurements_history_screen.dart';
import '../../progress/screens/progress_photos_screen.dart';
import '../../progress/widgets/transformation_studio_widget.dart';
import '../../progress/widgets/weight_chart_widget.dart';

/// Müşteri "Gelişim" sekmesi — gerçek verilerle çalışan ilerleme özeti.
class CustomerProgressScreen extends StatefulWidget {
  const CustomerProgressScreen({super.key});

  @override
  State<CustomerProgressScreen> createState() =>
      _CustomerProgressScreenState();
}

class _CustomerProgressScreenState extends State<CustomerProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Provider'ı başlat — bir sonraki frame'de çalıştır (context hazır olsun)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.firebaseUser?.uid;
      if (userId != null) {
        context.read<ProgressProvider>().startListening(
          userId,
          authProvider.userProfile,
        );
      }
    });
  }

  @override
  void dispose() {
    context.read<ProgressProvider>().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final progressProvider = context.watch<ProgressProvider>();
    final userProfile = authProvider.userProfile;

    final startDate = userProfile?.programStartDate;
    final dayCount = startDate != null
        ? DateTime.now().difference(startDate).inDays + 1
        : 0;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
              const SliverPadding(padding: EdgeInsets.only(top: 24)),

              // 1. Özet kartları
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSummaryGrid(
                    context,
                    progressProvider,
                    dayCount,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),

              // 2. Kilo Değişimi Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: progressProvider.isLoading
                      ? _buildLoadingCard(height: 260)
                      : WeightChartWidget(
                          entries: progressProvider.entries,
                          targetWeight: userProfile?.goal != null
                              ? double.tryParse(userProfile!.goal!)
                              : null,
                          initialWeight: userProfile?.weight,
                        ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),

              // 3. Dönüşüm Stüdyosu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dönüşüm Stüdyosu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.nightSky,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context
                                .goNamed(ProgressPhotosScreen.routeName),
                            child: Row(
                              children: [
                                Text(
                                  'Tüm Fotoğraflar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.chevron_right,
                                    color: AppColors.primary, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const TransformationStudioWidget(),
                    ],
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),

              // 4. Dijital Mezura
              SliverToBoxAdapter(
                child: progressProvider.isLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildLoadingCard(height: 180),
                      )
                    : _buildDigitalMeasure(context, progressProvider),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),

              // 5. Rozetler
              SliverToBoxAdapter(
                child: _buildBadges(context, progressProvider),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
      ),
    );
  }

  // ── Özet Grid ─────────────────────────────────────────────────────────────

  Widget _buildSummaryGrid(
    BuildContext context,
    ProgressProvider provider,
    int dayCount,
  ) {
    final change = provider.totalWeightChange;
    final changeStr = change == 0
        ? '0.0'
        : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}';

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            value: changeStr,
            label: 'KG TOPLAM',
            valueColor: change < 0 ? AppColors.primary : Colors.red,
            isHighlight: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            value: '$dayCount',
            label: 'GÜN SÜRE',
            valueColor: Colors.white,
            labelColor: Colors.white70,
            isHighlight: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            value: '${provider.currentStreak}',
            label: 'GÜN SERİ',
            valueColor: AppColors.primary,
            icon: Icons.local_fire_department,
            iconColor: const Color(0xFF9E3774),
            isHighlight: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String value,
    required String label,
    required Color valueColor,
    Color? labelColor,
    IconData? icon,
    Color? iconColor,
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlight ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          if (isHighlight)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: labelColor ?? Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dijital Mezura ────────────────────────────────────────────────────────

  Widget _buildDigitalMeasure(
    BuildContext context,
    ProgressProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dijital Mezura',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      context.goNamed(MeasurementsHistoryScreen.routeName),
                  child: Row(
                    children: [
                      Text(
                        'Tüm Kayıtlar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildMeasureItem(
            icon: Icons.straighten,
            iconBg: AppColors.primary.withValues(alpha: 0.1),
            iconColor: AppColors.primary,
            title: 'Bel',
            latestValue: provider.latestWaist,
            change: provider.waistChange,
          ),
          const SizedBox(height: 8),
          _buildMeasureItem(
            icon: Icons.straighten,
            iconBg: Colors.grey.shade200,
            iconColor: Colors.grey.shade600,
            title: 'Kalça',
            latestValue: provider.latestHip,
            change: provider.hipChange,
          ),
          const SizedBox(height: 8),
          _buildMeasureItem(
            icon: Icons.straighten,
            iconBg: const Color(0xFF9E3774).withValues(alpha: 0.1),
            iconColor: const Color(0xFF9E3774),
            title: 'Göğüs',
            latestValue: provider.latestChest,
            change: provider.chestChange,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required double? latestValue,
    required double? change,
  }) {
    final hasData = latestValue != null;
    final changeStr = change != null
        ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} cm'
        : null;
    final isPositive = change != null && change >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nightSky,
                  ),
                ),
                Text(
                  hasData
                      ? 'Son Ölçüm: ${latestValue.toStringAsFixed(1)} cm'
                      : 'Henüz ölçüm yok',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (hasData && changeStr != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  changeStr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.red : AppColors.primary,
                  ),
                ),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.red : AppColors.primary,
                  size: 16,
                ),
              ],
            )
          else if (!hasData)
            GestureDetector(
              onTap: () => context.goNamed(MeasurementsHistoryScreen.routeName),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ekle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Rozetler ──────────────────────────────────────────────────────────────

  Widget _buildBadges(BuildContext context, ProgressProvider provider) {
    final earned = provider.earnedBadges;
    final unearned = provider.unearnedBadges;
    final allBadges = [...earned, ...unearned];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rozetler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nightSky,
                ),
              ),
              Text(
                '${earned.length}/${allBadges.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: allBadges.map((badge) {
              final isEarned = earned.contains(badge);
              return _buildBadgeItem(badge: badge, isEarned: isEarned);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeItem({
    required BadgeDefinition badge,
    required bool isEarned,
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isEarned ? badge.bgColor : Colors.grey.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                if (isEarned)
                  BoxShadow(
                    color: badge.iconColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(
              badge.icon,
              color: isEarned ? badge.iconColor : Colors.grey.shade400,
              size: 36,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isEarned ? AppColors.nightSky : Colors.grey.shade400,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
