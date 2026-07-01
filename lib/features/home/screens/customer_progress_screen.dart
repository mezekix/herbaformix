import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/badge_model.dart';
import '../../../models/user_profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../progress/providers/progress_provider.dart';
import '../../progress/screens/progress_dashboard_screen.dart';
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
    // Rozet kazanıldığında snackbar göster
    ProgressProvider.onBadgeEarned = _onBadgeEarned;

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

  void _onBadgeEarned(String badgeId) {
    if (!mounted) return;
    final badge = AppBadges.findById(badgeId);
    if (badge == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(badge.icon, color: badge.iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yeni Rozet Kazandın!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    badge.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.nightSky,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    ProgressProvider.onBadgeEarned = null;
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
                    userProfile,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),

              // 1.5 Hedef İlerleme Çubuğu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildGoalProgressCard(context, progressProvider, userProfile),
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
                          targetWeight: userProfile?.targetWeight,
                          initialWeight: userProfile?.weight,
                          userGoal: userProfile?.userGoal,
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
                    : _buildDigitalMeasure(context, progressProvider, userProfile),
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
    UserProfileModel? userProfile,
  ) {
    final change = provider.totalWeightChange;
    final changeStr = change == 0
        ? '0.0'
        : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}';
    final isWeightLoss = userProfile?.userGoal == 'weight_loss';
    final isGoodChange = isWeightLoss ? change < 0 : change > 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            value: changeStr,
            label: 'KG TOPLAM',
            valueColor: change == 0 ? AppColors.nightSky : (isGoodChange ? AppColors.primary : Colors.red),
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

  Widget _buildGoalProgressCard(
    BuildContext context,
    ProgressProvider provider,
    UserProfileModel? userProfile,
  ) {
    final targetWeight = userProfile?.targetWeight;
    final currentWeight = provider.latestWeight ?? userProfile?.weight;

    // Hedef kilo yoksa veya mevcut kilo yoksa gösterme
    if (targetWeight == null || currentWeight == null) return const SizedBox.shrink();

    final initialWeight = userProfile?.weight ?? provider.entries.first.weight;
    final isLoss = targetWeight < initialWeight;

    // İlerleme yüzdesi hesapla
    double progress;
    if (isLoss) {
      final totalToLose = initialWeight - targetWeight;
      final lost = initialWeight - currentWeight;
      progress = totalToLose > 0 ? (lost / totalToLose).clamp(0.0, 1.0) : 0.0;
    } else {
      final totalToGain = targetWeight - initialWeight;
      final gained = currentWeight - initialWeight;
      progress = totalToGain > 0 ? (gained / totalToGain).clamp(0.0, 1.0) : 0.0;
    }

    final remaining = (currentWeight - targetWeight).abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.backgroundMuted),
        boxShadow: [
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hedef İlerlemesi',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nightSky,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progress >= 1.0 ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  progress >= 1.0 ? 'Ulaşıldı!' : '%${(progress * 100).round()}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: progress >= 1.0 ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Dairesel ilerleme göstergesi
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.backgroundMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? Colors.green : AppColors.primary,
                      ),
                    ),
                    Center(
                      child: Text(
                        '%${(progress * 100).round()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nightSky,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGoalInfoRow('Başlangıç', '${initialWeight.toStringAsFixed(1)} kg'),
                    const SizedBox(height: 6),
                    _buildGoalInfoRow('Mevcut', '${currentWeight.toStringAsFixed(1)} kg'),
                    const SizedBox(height: 6),
                    _buildGoalInfoRow('Hedef', '${targetWeight.toStringAsFixed(1)} kg'),
                    const SizedBox(height: 6),
                    _buildGoalInfoRow(
                      'Kalan',
                      '${remaining.toStringAsFixed(1)} kg',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.primary : AppColors.nightSky,
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
        border: isHighlight ? null : Border.all(color: AppColors.backgroundMuted),
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
              color: labelColor ?? AppColors.textMuted,
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
    UserProfileModel? userProfile,
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
                      context.goNamed(ProgressDashboardScreen.routeName),
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
            iconBg: const Color(0xFF9E3774).withValues(alpha: 0.1),
            iconColor: const Color(0xFF9E3774),
            title: 'Göğüs',
            latestValue: provider.latestFor(MeasurementType.chest),
            change: provider.changeFor(MeasurementType.chest),
            userGoal: userProfile?.userGoal,
          ),
          const SizedBox(height: 8),
          _buildMeasureItem(
            icon: Icons.straighten,
            iconBg: Colors.orange.withValues(alpha: 0.1),
            iconColor: Colors.orange,
            title: 'Göbek',
            latestValue: provider.latestFor(MeasurementType.belly),
            change: provider.changeFor(MeasurementType.belly),
            userGoal: userProfile?.userGoal,
          ),
          const SizedBox(height: 8),
          _buildMeasureItem(
            icon: Icons.straighten,
            iconBg: AppColors.primary.withValues(alpha: 0.1),
            iconColor: AppColors.primary,
            title: 'Bel',
            latestValue: provider.latestFor(MeasurementType.waist),
            change: provider.changeFor(MeasurementType.waist),
            userGoal: userProfile?.userGoal,
          ),
          const SizedBox(height: 8),
          _buildMeasureItem(
            icon: Icons.straighten,
            iconBg: AppColors.backgroundMuted,
            iconColor: AppColors.grey600,
            title: 'Kalça',
            latestValue: provider.latestFor(MeasurementType.hip),
            change: provider.changeFor(MeasurementType.hip),
            userGoal: userProfile?.userGoal,
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
    String? userGoal,
  }) {
    final hasData = latestValue != null;
    final changeStr = change != null
        ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} cm'
        : null;
    final isPositive = change != null && change >= 0;

    // Hedef bazlı renk: weight_loss ise azalış yeşil, weight_gain ise artış yeşil
    final isWeightLoss = userGoal == 'weight_loss';
    final isGoodChange = isWeightLoss ? !isPositive : isPositive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundMuted),
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
                    color: AppColors.textMuted,
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
                    color: isGoodChange ? AppColors.primary : Colors.red,
                  ),
                ),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isGoodChange ? AppColors.primary : Colors.red,
                  size: 16,
                ),
              ],
            )
          else if (!hasData)
            GestureDetector(
              onTap: () => context.goNamed(ProgressDashboardScreen.routeName),
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
              color: isEarned ? badge.bgColor : AppColors.backgroundMutedLight,
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
              color: isEarned ? badge.iconColor : AppColors.textMutedLight,
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
              color: isEarned ? AppColors.nightSky : AppColors.textMutedLight,
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
        border: Border.all(color: AppColors.backgroundMuted),
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
