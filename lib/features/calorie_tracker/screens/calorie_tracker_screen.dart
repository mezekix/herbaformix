import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/utils/calorie_calculation_engine.dart';
import '../../../models/user_profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../water_tracker/providers/water_provider.dart';
import '../../water_tracker/utils/water_calculation_constants.dart';
import '../providers/calorie_provider.dart';
import '../widgets/food_search_sheet.dart';
import 'calorie_history_screen.dart';

class CalorieTrackerScreen extends StatelessWidget {
  static const routeName = 'calorie-tracker';
  const CalorieTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalori Sayacı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () =>
                context.goNamed(CalorieHistoryScreen.routeName),
            tooltip: 'Geçmiş',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showGoalDialog(context),
            tooltip: 'Hedefi Düzenle',
          ),
        ],
      ),
      body: Consumer<CalorieProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          // Profil + aktivite seviyesi anlık olarak context.read ile alınır
          // (dinlemiyoruz — yalnız rozet/banner anlık değeri yansıtır).
          final profile = context.read<AuthProvider>().userProfile;
          final exerciseLevel =
              context.read<WaterProvider>().todaySummary?.exerciseLevel ??
                  'moderate';

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              provider.recomputeIfAuto(
                profile: profile,
                exerciseLevel: exerciseLevel,
              );
            }
          });

          final missing = provider.missingProfileFields(profile);
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (missing.isNotEmpty) ...[
                  _ProfileIncompleteBanner(missing: missing),
                  const SizedBox(height: 12),
                ],
                _buildProgressCard(
                  context,
                  provider,
                  profile: profile,
                  exerciseLevel: exerciseLevel,
                ),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildMealList(context, provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(context),
        label: const Text('Öğün Ekle'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    CalorieProvider provider, {
    required UserProfileModel? profile,
    required String exerciseLevel,
  }) {
    final consumed = provider.totalCalories;
    final goal = provider.calorieGoal;
    final remaining = goal - consumed;
    final overGoal = consumed > goal;
    final progress = provider.progress.clamp(0.0, 1.0);
    final color = overGoal ? Colors.orange : AppColors.primary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Üst kısım: ring + büyük "kalan/aşılan" sayı yan yana
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return SizedBox(
                            width: 110,
                            height: 110,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 10,
                              backgroundColor: AppColors.backgroundMuted,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            'tamamlandı',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        overGoal
                            ? '${remaining.abs()}'
                            : '$remaining',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        overGoal ? 'kcal hedefin üstünde' : 'kcal kaldı',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alt kısım: linear progress + tüketilen/hedef metrikleri
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.backgroundMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat('Tüketilen', '$consumed kcal', color),
                _miniStat(
                  'Hedef',
                  '$goal kcal',
                  AppColors.grey700,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Rozet — overflow korumalı, Row içinde Flexible ile sarılı
            _GoalSourceBadge(
              provider: provider,
              profile: profile,
              exerciseLevel: exerciseLevel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.grey600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMealList(BuildContext context, CalorieProvider provider) {
    final meals = provider.meals;

    if (meals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Bugün hiç öğün eklenmedi.\nSağ alttaki (+) butonuyla başlayın.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bugünkü Öğünler',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meals.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final meal = meals[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              leading: const Icon(
                Icons.restaurant_menu,
                color: AppColors.primary,
              ),
              title: Text(
                meal.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(DateFormat('HH:mm').format(meal.timestamp)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${meal.calories} kcal',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Öğünü sil',
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => provider.removeMeal(meal.id),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddMealDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FoodSearchSheet(),
    );
  }

  Future<void> _showGoalDialog(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final water = Provider.of<WaterProvider>(context, listen: false);
    await showDialog<void>(
      context: context,
      builder: (ctx) => _GoalSettingsDialog(
        profile: auth.userProfile,
        exerciseLevel: water.todaySummary?.exerciseLevel ?? 'moderate',
      ),
    );
  }
}

/// Profil eksikse kalori ekranının üstünde tıklanabilir bir banner.
/// Hangi alanların eksik olduğunu söyler ve profil ekranına götürür.
/// Profil tamamlanınca otomatik olarak gizlenir.
class _ProfileIncompleteBanner extends StatelessWidget {
  final List<String> missing;

  const _ProfileIncompleteBanner({required this.missing});

  @override
  Widget build(BuildContext context) {
    final missingText = missing.join(', ');
    return InkWell(
      onTap: () => context.goNamed('personal-info'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: Colors.amber.shade800,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalori hedefin tahmini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sana özel hesaplama için $missingText bilgilerini doldur.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.amber.shade800,
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress kart altındaki küçük gösterge — "Otomatik (orta aktivite)" /
/// "Manuel" şeklinde. Kullanıcıya hedefin nereden geldiğini anlık olarak
/// söyler; profil eksikse uyarı verir.
class _GoalSourceBadge extends StatelessWidget {
  final CalorieProvider provider;
  final UserProfileModel? profile;
  final String exerciseLevel;

  const _GoalSourceBadge({
    required this.provider,
    required this.profile,
    required this.exerciseLevel,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isAutoGoal) {
      final preview = provider.computeGoalPreview(
        profile: profile,
        exerciseLevel: exerciseLevel,
      );
      // Profil tamsa "Otomatik • Aktivite: orta" — değilse banner zaten üstte
      // uyarı veriyor, rozet kısa kalsın: "Tahmini hedef".
      if (preview == null || !preview.isComplete) {
        return _badge(
          icon: Icons.help_outline,
          label: 'Tahmini hedef',
          color: Colors.amber.shade800,
        );
      }
      return _badge(
        icon: Icons.auto_awesome,
        label: 'Otomatik • Aktivite: ${_exerciseLevelLabel(preview.exerciseLevel)}',
        color: AppColors.primary,
      );
    }
    return _badge(
      icon: Icons.edit_outlined,
      label: 'Manuel hedef',
      color: AppColors.grey700,
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _exerciseLevelLabel(String level) {
  switch (level) {
    case WaterCalculationConstants.exerciseSedentary:
      return 'hareketsiz';
    case WaterCalculationConstants.exerciseLight:
      return 'hafif';
    case WaterCalculationConstants.exerciseModerate:
      return 'orta';
    case WaterCalculationConstants.exerciseHeavy:
      return 'yüksek';
    default:
      return level;
  }
}

/// Hedef düzenleme diyaloğu — Otomatik / Manuel iki mod.
///
/// **Otomatik**: profil + bugünkü aktivite seviyesinden anlık hesaplama.
/// BMR, TDEE, aktivite çarpanı ve hedef offset ayrı satırlarda gösterilir.
/// Profil eksikse uyarı çıkar, "Kaydet" devre dışı.
///
/// **Manuel**: serbest kalori girişi. Kaydedildiğinde isAutoGoal=false olur;
/// otomatik recompute saygı duyup ezmez.
class _GoalSettingsDialog extends StatefulWidget {
  final UserProfileModel? profile;
  final String exerciseLevel;

  const _GoalSettingsDialog({
    required this.profile,
    required this.exerciseLevel,
  });

  @override
  State<_GoalSettingsDialog> createState() => _GoalSettingsDialogState();
}

class _GoalSettingsDialogState extends State<_GoalSettingsDialog> {
  late bool _isAuto;
  late TextEditingController _manualController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CalorieProvider>(context, listen: false);
    _isAuto = provider.isAutoGoal;
    _manualController =
        TextEditingController(text: provider.calorieGoal.toString());
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = Provider.of<CalorieProvider>(context, listen: false);
    setState(() => _isSaving = true);
    try {
      if (_isAuto) {
        final ok = await provider.switchToAutoGoal(
          profile: widget.profile,
          exerciseLevel: widget.exerciseLevel,
        );
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Otomatik hesaplama için profilinde boy, kilo, yaş ve cinsiyet bilgisi olmalı.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      } else {
        final value = int.tryParse(_manualController.text.trim());
        if (value == null || value <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lütfen geçerli bir kalori değeri girin.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
        await provider.setManualGoal(value);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalorieProvider>(context, listen: false);
    final preview = provider.computeGoalPreview(
      profile: widget.profile,
      exerciseLevel: widget.exerciseLevel,
    );

    return AlertDialog(
      title: const Text('Günlük Hedefi Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mod seçici — ikon yok, seçili tik gizli; "Otomatik" yazısı tek
            // satıra sığsın diye sade tutuldu.
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Otomatik')),
                  ButtonSegment(value: false, label: Text('Manuel')),
                ],
                selected: {_isAuto},
                onSelectionChanged: (set) =>
                    setState(() => _isAuto = set.first),
              ),
            ),
            const SizedBox(height: 16),

            // Otomatik mod içeriği
            if (_isAuto) _buildAutoContent(preview),
            // Manuel mod içeriği
            if (!_isAuto) _buildManualContent(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check, size: 18),
          label: const Text('Kaydet'),
        ),
      ],
    );
  }

  Widget _buildAutoContent(CalorieGoalResult? preview) {
    if (preview == null || !preview.isComplete) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_outlined,
                color: Colors.orange.shade800, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Otomatik hesaplama için profilinde boy, kilo, yaş ve cinsiyet '
                'bilgisinin tamamlanmış olması gerekir. Profilini güncelleyip '
                'tekrar dene.',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profilinden ve bugünkü aktivite seviyenden hesaplanır:',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        _detailRow('Bazal Metabolizma (BMR)', '${preview.bmrKcal} kcal'),
        _detailRow(
          'Günlük Harcama (TDEE)',
          '${preview.tdeeKcal} kcal',
          subtitle:
              'Aktivite: ${_exerciseLevelLabel(preview.exerciseLevel)} (×${preview.activityMultiplier.toStringAsFixed(3)})',
        ),
        _detailRow(
          'Hedef Düzeltmesi',
          '${preview.goalOffsetKcal >= 0 ? '+' : ''}${preview.goalOffsetKcal} kcal',
          subtitle: _goalOffsetExplanation(preview.goalOffsetKcal),
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Günlük Hedef',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '${preview.totalKcal} kcal',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Su tracker\'da aktivite seviyeni değiştirdiğinde kalori hedefin de otomatik güncellenir.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kendi belirlediğin bir kalori hedefi gir:',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _manualController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Günlük Kalori Hedefi (kcal)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _goalOffsetExplanation(int offset) {
    if (offset < 0) return 'Zayıflama hedefi (haftada ~${(-offset * 7 / 7700).toStringAsFixed(1)} kg)';
    if (offset > 0) return 'Kilo alma hedefi (haftada ~${(offset * 7 / 7700).toStringAsFixed(1)} kg)';
    return 'Kilo korunma';
  }
}

