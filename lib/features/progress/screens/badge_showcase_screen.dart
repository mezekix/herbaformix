import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/badge_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/progress_provider.dart';

class BadgeShowcaseScreen extends StatefulWidget {
  static const String routeName = 'badge-showcase';

  const BadgeShowcaseScreen({super.key});

  @override
  State<BadgeShowcaseScreen> createState() => _BadgeShowcaseScreenState();
}

class _BadgeShowcaseScreenState extends State<BadgeShowcaseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.firebaseUser?.uid;
      if (userId == null) return;

      context.read<ProgressProvider>().startListening(
            userId,
            authProvider.userProfile,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.nightSky),
        title: const Text(
          'Rozet Vitrini',
          style: TextStyle(
            color: AppColors.nightSky,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<ProgressProvider>(
        builder: (context, provider, _) {
          final earnedIds = provider.earnedBadgeIds.toSet();
          final earnedCount = earnedIds.length;
          final totalCount = AppBadges.all.length;
          final progress = totalCount == 0 ? 0.0 : earnedCount / totalCount;

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider = context.read<AuthProvider>();
              final userId = authProvider.firebaseUser?.uid;
              if (userId != null) {
                provider.startListening(userId, authProvider.userProfile);
              }
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: _buildSummaryCard(
                      earnedCount: earnedCount,
                      totalCount: totalCount,
                      progress: progress,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final badge = AppBadges.all[index];
                        return _BadgeTile(
                          badge: badge,
                          isEarned: earnedIds.contains(badge.id),
                        );
                      },
                      childCount: AppBadges.all.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required int earnedCount,
    required int totalCount,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.backgroundMuted),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.mango.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.mangoDeep,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Koleksiyon İlerlemesi',
                      style: TextStyle(
                        color: AppColors.nightSky,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$earnedCount / $totalCount rozet kazanıldı',
                      style: const TextStyle(
                        color: AppColors.grey600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '%${(progress * 100).round()}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: AppColors.backgroundMuted,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isEarned;

  const _BadgeTile({
    required this.badge,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEarned
              ? badge.iconColor.withValues(alpha: 0.35)
              : AppColors.backgroundMuted,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: isEarned ? badge.bgColor : AppColors.backgroundMuted,
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                badge.icon,
                color: isEarned ? badge.iconColor : AppColors.textMutedLight,
                size: 36,
              ),
              if (!isEarned)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: AppColors.grey600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isEarned ? AppColors.nightSky : AppColors.grey600,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isEarned
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.backgroundMutedLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isEarned ? 'Kazanıldı' : 'Kilitli',
              style: TextStyle(
                color: isEarned ? AppColors.garden : AppColors.grey600,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
