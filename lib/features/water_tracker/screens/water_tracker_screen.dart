import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../providers/water_provider.dart';

class WaterTrackerScreen extends StatelessWidget {
  static const String routeName = 'water-tracker';
  const WaterTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Su Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay_outlined),
            onPressed: () => _showResetConfirmationDialog(context),
            tooltip: 'Günü Sıfırla',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Hedefi Düzenle',
          ),
        ],
      ),
      body: Consumer<WaterProvider>(
        builder: (context, waterProvider, child) {
          if (waterProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () =>
                waterProvider.resetDailyProgress(), // Günü sıfırlamak için
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildProgressCircle(context, waterProvider),
                const SizedBox(height: 24),
                _buildQuickAddButtons(context, waterProvider),
                const SizedBox(height: 24),
                _buildHistoryList(context, waterProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCircle(
    BuildContext context,
    WaterProvider waterProvider,
  ) {
    final theme = Theme.of(context);
    final progress = waterProvider.progress;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 2,
              blurRadius: 10,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(AppColors.aqua, AppColors.mango, progress) ??
                    AppColors.aqua,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.water_drop,
                    color: AppColors.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${waterProvider.totalConsumed} ml',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '/ ${waterProvider.dailyGoal} ml',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButtons(
    BuildContext context,
    WaterProvider waterProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hızlı Ekle',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0,
          runSpacing: 12.0,
          children: [
            _buildWaterButton(context, 250, waterProvider),
            _buildWaterButton(context, 330, waterProvider),
            _buildWaterButton(context, 500, waterProvider),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Özel Miktar'),
              onPressed: () => _showAddCustomWaterDialog(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (waterProvider.todayLogs.isNotEmpty)
          TextButton.icon(
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Son Eylemi Geri Al'),
            onPressed: () {
              waterProvider.removeLastLog();
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Son su alımı geri alındı.'),
                    duration: Duration(seconds: 2),
                  ),
                );
            },
          ),
      ],
    );
  }

  Widget _buildWaterButton(
    BuildContext context,
    int amount,
    WaterProvider waterProvider,
  ) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add_circle_outline),
      label: Text('$amount ml'),
      onPressed: () {
        waterProvider.addWater(amount);
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('$amount ml su eklendi!'),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, WaterProvider waterProvider) {
    final logs = waterProvider.todayLogs.reversed.toList();
    if (logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            'Bugün henüz su içmediniz.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gün İçi Tüketim', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.aqua,
                child: Icon(
                  Icons.water_drop_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text('${log.amount} ml su eklendi'),
              subtitle: Text(DateFormat.Hm().format(log.time)), // Saat:Dakika
              dense: true,
            );
          },
        ),
      ],
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Günü Sıfırla'),
        content: const Text(
          'Bugünkü tüm su tüketim kayıtlarınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sıfırla'),
            onPressed: () {
              waterProvider.resetDailyProgress();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Günlük ilerleme sıfırlandı.')),
                );
            },
          ),
        ],
      ),
    );
  }

  void _showAddCustomWaterDialog(BuildContext context) {
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Özel Miktar Ekle'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Miktar (ml)',
                suffixText: 'ml',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen bir miktar girin.';
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Geçerli bir miktar girin.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final amount = int.parse(amountController.text);
                  waterProvider.addWater(amount);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('$amount ml su eklendi!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final goalController = TextEditingController(
      text: waterProvider.dailyGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Günlük Hedefi Ayarla'),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hedef (ml)',
              suffixText: 'ml',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newGoal = int.tryParse(goalController.text);
                if (newGoal != null && newGoal > 0) {
                  waterProvider.setDailyGoal(newGoal);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hedef güncellendi!')),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}
