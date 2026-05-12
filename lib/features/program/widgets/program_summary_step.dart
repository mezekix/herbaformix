import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/products/providers/product_provider.dart';
import '../models/program_model.dart';
import '../providers/program_provider.dart';

class ProgramSummaryStep extends StatelessWidget {
  const ProgramSummaryStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgramProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid ?? '';
    final allProducts = context.read<ProductProvider>().products;

    if (userId.isEmpty) {
      return const Center(child: Text('Kullanıcı oturumu bulunamadı.'));
    }

    final goalLabels = {
      'weight_loss': '🔥 Kilo Ver',
      'healthy_living': '🌿 Sağlıklı Yaşa',
      'weight_gain': '💪 Kilo Al',
    };

    final today = DateFormat('d MMMM yyyy', 'tr_TR').format(DateTime.now());
    final endDate = DateTime(
      DateTime.now().year,
      DateTime.now().month + provider.durationMonths,
      DateTime.now().day,
    );
    final endDateStr = DateFormat('d MMMM yyyy', 'tr_TR').format(endDate);

    // Sıralı slotlar
    final sortedSlots = List<MealSlot>.from(provider.slots)
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Programın Hazır!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.nightSky,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Detayları kontrol et ve programını başlat.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Hedef & süre kartı
          _Card(children: [
            _Row(icon: Icons.flag_outlined,
                label: 'Hedef',
                value: goalLabels[provider.selectedGoal] ?? '-'),
            _Row(icon: Icons.calendar_month,
                label: 'Süre',
                value: '${provider.durationMonths} ay'),
            _Row(icon: Icons.play_circle_outline,
                label: 'Başlangıç',
                value: today),
            _Row(icon: Icons.stop_circle_outlined,
                label: 'Bitiş',
                value: endDateStr),
            if (provider.selectedGoal == 'weight_loss' &&
                provider.currentWeight != null &&
                provider.targetWeight != null) ...[
              _Row(icon: Icons.monitor_weight_outlined,
                  label: 'Mevcut Kilo',
                  value: '${provider.currentWeight} kg'),
              _Row(icon: Icons.flag,
                  label: 'Hedef Kilo',
                  value: '${provider.targetWeight} kg'),
            ],
          ]),

          const SizedBox(height: 14),

          // Öğün planı kartı
          _Card(
            title: '🍽️ Günlük Program',
            children: sortedSlots.map((slot) {
              final waterTime = calculateWaterStepTime(slot.scheduledTime);
              return _SlotSummaryRow(slot: slot, waterTime: waterTime);
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Su & bildirim bilgisi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyan.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.cyan, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Her ana öğününden 30 dk önce 500ml su hatırlatması eklenecek.',
                    style: TextStyle(fontSize: 12, color: Colors.cyan.shade800),
                  ),
                ),
              ],
            ),
          ),

          if (provider.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(provider.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    debugPrint('[Summary] saveProgram başlatılıyor, userId=$userId, slots=${provider.slots.length}');
                    
                    // Validasyon: en az bir slotta ürün olmalı
                    final hasProducts = provider.slots.any(
                      (s) => !s.isNormalMeal && s.products.isNotEmpty,
                    );
                    if (!hasProducts) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('En az bir öğüne ürün eklemelisin.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final success =
                        await provider.saveProgram(userId, allProducts);
                    debugPrint('[Summary] saveProgram sonucu: $success, error: ${provider.errorMessage}');
                    if (success && context.mounted) {
                      // Program başladığında gün sayacını sıfırla
                      final userProfile = authProvider.userProfile;
                      if (userProfile != null) {
                        userProfile.programStartDate = DateTime.now();
                        await authProvider.updateUserProfile(userProfile);
                      }
                      if (context.mounted) {
                        context.pop();
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: provider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('🚀 Programı Başlat',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: provider.isLoading ? null : () => provider.previousStep(),
            child: const Text('← Geri Dön'),
          ),
        ],
      ),
    );
  }
}

class _SlotSummaryRow extends StatelessWidget {
  final MealSlot slot;
  final String waterTime;

  const _SlotSummaryRow({required this.slot, required this.waterTime});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon(slot.kind), size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.label,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                Text(
                  slot.isNormalMeal ? 'Normal Yemek' : slot.summary,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: slot.isNormalMeal
                        ? Colors.grey.shade600
                        : AppColors.nightSky,
                  ),
                ),
                if (!slot.isNormalMeal && slot.products.isNotEmpty)
                  Text(
                    '💧 Su: $waterTime',
                    style: TextStyle(
                        fontSize: 11, color: Colors.cyan.shade600),
                  ),
              ],
            ),
          ),
          Text(
            slot.scheduledTime,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(MealSlotKind kind) {
    switch (kind) {
      case MealSlotKind.morning:
        return Icons.wb_sunny_outlined;
      case MealSlotKind.lunch:
        return Icons.wb_cloudy_outlined;
      case MealSlotKind.evening:
        return Icons.nights_stay_outlined;
      case MealSlotKind.snack:
        return Icons.coffee_outlined;
    }
  }
}

class _Card extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _Card({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.nightSky)),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.nightSky)),
        ],
      ),
    );
  }
}
