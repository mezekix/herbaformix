import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/progress_entry_model.dart';
import '../providers/progress_provider.dart';
import '../widgets/add_measurement_sheet.dart';
import '../widgets/weight_chart_widget.dart';
import 'measurements_history_screen.dart';

class ProgressDashboardScreen extends StatefulWidget {
  static const String routeName = 'progress-dashboard';

  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: _buildAppBar(),
      body: Consumer<ProgressProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.entries.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider = context.read<AuthProvider>();
              final userId = authProvider.firebaseUser?.uid;
              if (userId != null) {
                provider.startListening(userId, authProvider.userProfile);
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverviewCards(context, provider),
                const SizedBox(height: 16),
                _buildStatsSummary(context, provider),
                const SizedBox(height: 24),
                _buildChartSection(context, provider),
                const SizedBox(height: 24),
                _buildRecentEntriesHeader(),
                const SizedBox(height: 12),
                _buildRecentEntries(provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Ölçüm Ekle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _exportCSV(BuildContext context) async {
    final provider = context.read<ProgressProvider>();
    if (provider.entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarılacak veri yok.')),
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      // Başlık
      buffer.writeln(
        'Tarih,Kilo (kg),BMI,Bel (cm),Kalça (cm),Göğüs (cm),Kol (cm),Bacak (cm),Yağ Oranı (%),Kas Kütlesi (kg)',
      );
      // Satırlar
      for (final e in provider.entries) {
        buffer.writeln(
          '${DateFormat('yyyy-MM-dd').format(e.date)},'
          '${e.weight},'
          '${e.bmi ?? ''},'
          '${e.waist ?? ''},'
          '${e.hip ?? ''},'
          '${e.chest ?? ''},'
          '${e.arm ?? ''},'
          '${e.thigh ?? ''},'
          '${e.bodyFat ?? ''},'
          '${e.muscleMass ?? ''}',
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gelisim_olcumleri.csv');
      await file.writeAsString(buffer.toString());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Gelişim Ölçümleri',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dışa aktarma hatası: $e')),
        );
      }
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF7F8F6),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Gelişimim',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.nightSky,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.nightSky),
      actions: [
        Consumer<ProgressProvider>(
          builder: (context, provider, _) {
            final isPrivacyMode = provider.isPrivacyMode;
            return IconButton(
              tooltip: isPrivacyMode ? 'Gizlilik Modunu Kapat' : 'Gizlilik Modunu Aç',
              icon: Icon(
                isPrivacyMode ? Icons.visibility_off : Icons.visibility,
                color: isPrivacyMode ? AppColors.primary : Colors.grey,
              ),
              onPressed: () => provider.togglePrivacyMode(),
            );
          },
        ),
        IconButton(
          tooltip: 'Ölçüm Geçmişi',
          icon: const Icon(Icons.history, color: AppColors.primary),
          onPressed: () => context.goNamed(MeasurementsHistoryScreen.routeName),
        ),
        IconButton(
          tooltip: 'CSV Olarak Dışa Aktar',
          icon: const Icon(Icons.download, color: AppColors.primary),
          onPressed: () => _exportCSV(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOverviewCards(BuildContext context, ProgressProvider provider) {
    final change = provider.totalWeightChange;
    final latestWeight = provider.latestWeight;
    final isPrivacy = provider.isPrivacyMode;
    final streak = provider.currentStreak;

    final userProfile = context.read<AuthProvider>().userProfile;
    final isWeightLoss = userProfile?.userGoal == 'weight_loss';
    final isGoodChange = isWeightLoss ? change < 0 : change > 0;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildStatCard(
            title: isPrivacy ? 'Son BMI' : 'Son Kilo',
            value: isPrivacy 
              ? (provider.entries.last.bmi?.toStringAsFixed(1) ?? '—') 
              : (latestWeight != null ? '${latestWeight.toStringAsFixed(1)} kg' : '—'),
            subtitle: change == 0
                ? 'Değişim Yok'
                : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
            subtitleColor: change == 0 ? Colors.grey : (isGoodChange ? AppColors.primary : Colors.red),
            icon: Icons.monitor_weight_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildStatCard(
            title: 'Seri',
            value: '$streak Gün',
            subtitle: 'Harika gidiyorsun!',
            subtitleColor: AppColors.mangoDeep,
            icon: Icons.local_fire_department,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummary(BuildContext context, ProgressProvider provider) {
    if (provider.entries.length < 2) return const SizedBox.shrink();

    final weeklyAvg = provider.weeklyAverageChange;
    final bestWeek = provider.bestWeekSummary;
    final totalEntries = provider.totalEntries;
    final isWeightLoss = context.read<AuthProvider>().userProfile?.userGoal == 'weight_loss';
    final isGoodAvg = isWeightLoss ? weeklyAvg < 0 : weeklyAvg > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'İstatistikler',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nightSky,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            'Haftalık Ortalama',
            '${weeklyAvg >= 0 ? '+' : ''}${weeklyAvg.toStringAsFixed(2)} kg/hafta',
            weeklyAvg == 0 ? AppColors.nightSky : (isGoodAvg ? AppColors.primary : Colors.red),
          ),
          const SizedBox(height: 8),
          _buildStatItem(
            'Toplam Kayıt',
            '$totalEntries',
            AppColors.nightSky,
          ),
          const SizedBox(height: 8),
          _buildStatItem(
            'En İyi Hafta',
            bestWeek,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.nightSky),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, ProgressProvider provider) {
    final userProfile = context.read<AuthProvider>().userProfile;

    return WeightChartWidget(
      entries: provider.entries,
      targetWeight: userProfile?.targetWeight,
      initialWeight: userProfile?.weight,
      isPrivacyMode: provider.isPrivacyMode,
      userGoal: userProfile?.userGoal,
    );
  }

  Widget _buildRecentEntriesHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tüm Kayıtlar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.nightSky),
        ),
      ],
    );
  }

  Widget _buildRecentEntries(ProgressProvider provider) {
    // Tüm kayıtları tarihe göre azalan şekilde (en yeni en üstte) göster
    final entries = [...provider.entries]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: entries.map((entry) {
        final isPrivacy = provider.isPrivacyMode;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('d MMMM yyyy', 'tr_TR').format(entry.date),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.nightSky),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPrivacy 
                        ? 'BMI: ${entry.bmi?.toStringAsFixed(1) ?? "—"}' 
                        : '${entry.weight.toStringAsFixed(1)} kg',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditSheet(context, entry);
                  } else if (value == 'delete') {
                    _confirmDelete(context, provider, entry);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Düzenle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Sil', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_weight_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Henüz ölçüm kaydı yok',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk ölçümünü ekleyerek başla',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMeasurementSheet(),
    );
  }

  void _openEditSheet(BuildContext context, ProgressEntryModel entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMeasurementSheet(entry: entry),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProgressProvider provider, ProgressEntryModel entry) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userProfile?.id;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ölçümü Sil', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.nightSky)),
        content: const Text('Bu ölçüm kaydını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.', style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.deleteEntry(userId, entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ölçüm kaydı silindi.'), backgroundColor: AppColors.primary),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silinirken hata oluştu: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
