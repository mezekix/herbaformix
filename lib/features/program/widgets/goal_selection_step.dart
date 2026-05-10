import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../providers/program_provider.dart';

class GoalSelectionStep extends StatelessWidget {
  const GoalSelectionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgramProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Programın amacı ne?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.nightSky,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hedefine göre sana özel bir program oluşturacağız.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          _GoalCard(
            goalKey: 'weight_loss',
            title: 'Kilo Ver',
            subtitle: 'Sağlıklı ve kalıcı kilo kaybı',
            emoji: '🔥',
            color: const Color(0xFFFF6B6B),
            selected: provider.selectedGoal == 'weight_loss',
            onTap: () => provider.setGoal('weight_loss'),
          ),
          const SizedBox(height: 16),

          _GoalCard(
            goalKey: 'healthy_living',
            title: 'Sağlıklı Yaşa',
            subtitle: 'Dengeli beslenme ve enerji',
            emoji: '🌿',
            color: AppColors.primary,
            selected: provider.selectedGoal == 'healthy_living',
            onTap: () => provider.setGoal('healthy_living'),
          ),
          const SizedBox(height: 16),

          _GoalCard(
            goalKey: 'weight_gain',
            title: 'Kilo Al',
            subtitle: 'Kas kütlesi ve güç kazanımı',
            emoji: '💪',
            color: const Color(0xFF4A90D9),
            selected: provider.selectedGoal == 'weight_gain',
            onTap: () => provider.setGoal('weight_gain'),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: provider.selectedGoal == null
                ? null
                : () => provider.nextStep(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text(
              'Devam Et',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String goalKey;
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goalKey,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: selected ? color : AppColors.nightSky,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
