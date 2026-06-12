import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/water_log_model.dart';
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
                _buildExerciseSelector(context, waterProvider),
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 280,
          maxHeight: 280,
        ),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '/ ${waterProvider.dailyGoal} ml',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _showTargetDetailsBottomSheet(context, waterProvider),
                            child: const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseSelector(BuildContext context, WaterProvider waterProvider) {
    final currentLevel = waterProvider.todaySummary?.exerciseLevel ?? 'sedentary';
    final theme = Theme.of(context);

    final levels = [
      {'key': 'sedentary', 'label': 'Hareketsiz'},
      {'key': 'light', 'label': 'Hafif'},
      {'key': 'moderate', 'label': 'Orta'},
      {'key': 'heavy', 'label': 'Yoğun'},
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          children: [
            Text(
              'Bugünkü Aktivite Seviyen',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: levels.map((lvl) {
                final isSelected = currentLevel == lvl['key'];
                return ChoiceChip(
                  label: Text(lvl['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      waterProvider.setExerciseLevel(lvl['key'] as String);
                    }
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
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
        Row(
          children: [
            Expanded(child: _buildWaterButton(context, 250, waterProvider)),
            const SizedBox(width: 12),
            Expanded(child: _buildWaterButton(context, 330, waterProvider)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildWaterButton(context, 500, waterProvider)),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_task_outlined),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Özel Miktar'),
                ),
                onPressed: () => _showAddCustomWaterDialog(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('$amount ml'),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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
                  color: AppColors.bay,
                  size: 20,
                ),
              ),
              title: Text('${log.amount} ml su eklendi'),
              subtitle: Text(DateFormat.Hm().format(log.time)),
              dense: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: Colors.grey.shade600),
                    tooltip: 'Düzenle',
                    onPressed: () {
                      _showEditWaterDialog(context, waterProvider, log);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: Colors.grey.shade400),
                    tooltip: 'Sil',
                    onPressed: () {
                      waterProvider.removeLog(log.id);
                    },
                  ),
                ],
              ),
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

  Future<void> _showAddCustomWaterDialog(BuildContext context) async {
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return CustomWaterDialog(formKey: formKey, amountController: amountController, waterProvider: waterProvider);
      },
    );
    amountController.dispose();
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    final goalController = TextEditingController(
      text: waterProvider.dailyGoal.toString(),
    );

    await showDialog(
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
    goalController.dispose();
  }

  void _showTargetDetailsBottomSheet(BuildContext context, WaterProvider waterProvider) {
    final profile = waterProvider.userProfile;
    final summary = waterProvider.todaySummary;
    final program = waterProvider.activeProgram;
    final theme = Theme.of(context);

    if (profile == null || summary == null) return;

    final double weight = profile.weight ?? 70.0;
    final double baseWater = weight * 33.0;

    final isFemale = (profile.gender ?? 'Erkek').toLowerCase() == 'kadın';
    final double genderEffect = isFemale ? (baseWater * -0.10) : 0.0;

    final int age = profile.age ?? 25;
    double ageEffect = 0.0;
    if (age > 30 && age <= 55) {
      ageEffect = (baseWater + genderEffect) * -0.05;
    } else if (age > 55) {
      ageEffect = (baseWater + genderEffect) * -0.10;
    }

    int exerciseEffect = 0;
    switch (summary.exerciseLevel) {
      case 'light': exerciseEffect = 350; break;
      case 'moderate': exerciseEffect = 600; break;
      case 'heavy': exerciseEffect = 1000; break;
    }

    int weatherEffect = 0;
    final temp = summary.weatherTemp;
    if (temp != null) {
      if (temp < 15) {
        weatherEffect += -200;
      } else if (temp > 25 && temp <= 30) {
        weatherEffect += 300;
      } else if (temp > 30 && temp <= 35) {
        weatherEffect += 500;
      } else if (temp > 35) {
        weatherEffect += 700;
      }
    }

    int humidityEffect = 0;
    final hum = summary.weatherHumidity;
    if (hum != null) {
      if (hum < 60) {
        humidityEffect += 200;
      } else if (hum > 75) {
        humidityEffect += 150;
      }
    }

    int herbalifeEffect = 0;
    int shakeCount = 0;
    bool hasAloe = false;
    bool hasTea = false;
    bool hasFiber = false;
    int totalProducts = 0;

    if (program != null && program.isActive) {
      for (final slot in program.slots) {
        if (slot.isNormalMeal) continue;
        for (final product in slot.products) {
          final name = product.productName.toLowerCase();
          totalProducts++;
          if (name.contains('shake') || name.contains('formul 1') || name.contains('formül 1')) {
            shakeCount++;
          } else if (name.contains('aloe')) {
            hasAloe = true;
          } else if (name.contains('çay') || name.contains('cay') || name.contains('bitkisel konsantre')) {
            hasTea = true;
          } else if (name.contains('fiber') || name.contains('lif')) {
            hasFiber = true;
          }
        }
      }
      herbalifeEffect += shakeCount * 200;
      if (hasAloe) herbalifeEffect += 100;
      if (hasTea) herbalifeEffect += -100;
      if (hasFiber) herbalifeEffect += 150;
      if (totalProducts >= 4) herbalifeEffect += 300;
    }

    final String healthNotesLower = (profile.healthNotes ?? '').toLowerCase();
    int healthEffect = 0;
    if (healthNotesLower.contains('diyabet') || healthNotesLower.contains('seker') || healthNotesLower.contains('şeker')) {
      healthEffect = 200;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '💧 Hedef Hesaplama Detayı',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(),
              _buildDetailRow('Temel İhtiyaç (${weight.toStringAsFixed(0)} kg × 33 ml)', '${baseWater.round()} ml'),
              if (isFemale) _buildDetailRow('Cinsiyet Düzeltmesi (Kadın -%10)', '${genderEffect.round()} ml', isNegative: true),
              if (ageEffect != 0) _buildDetailRow('Yaş Düzeltmesi ($age yaş)', '${ageEffect.round()} ml', isNegative: true),
              if (exerciseEffect != 0) _buildDetailRow('Egzersiz Etkisi', '+$exerciseEffect ml'),
              if (weatherEffect != 0) _buildDetailRow('Hava Durumu (${temp?.toStringAsFixed(1)}°C)', weatherEffect > 0 ? '+$weatherEffect ml' : '$weatherEffect ml', isNegative: weatherEffect < 0),
              if (humidityEffect != 0) _buildDetailRow('Nem Oranı (%${hum?.toStringAsFixed(0)})', '+$humidityEffect ml'),
              if (herbalifeEffect != 0) _buildDetailRow('Herbalife Ürünleri Etkisi', herbalifeEffect > 0 ? '+$herbalifeEffect ml' : '$herbalifeEffect ml', isNegative: herbalifeEffect < 0),
              if (healthEffect != 0) _buildDetailRow('Sağlık Durumu Düzeltmesi (Diyabet)', '+$healthEffect ml'),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bugünkü Su Hedefin',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${waterProvider.dailyGoal} ml',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                summary.isWeatherFetched 
                    ? '☀️ Anlık konum hava durumuna göre otomatik güncellenmiştir.' 
                    : '☁️ Hava durumuna ulaşılamadı, standart hesaplama uygulandı.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isNegative ? AppColors.error : (value.startsWith('+') ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditWaterDialog(BuildContext context, WaterProvider waterProvider, WaterLogModel log) {
    showDialog(
      context: context,
      builder: (context) {
        return EditWaterDialog(waterProvider: waterProvider, log: log);
      },
    );
  }
}

class CustomWaterDialog extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final WaterProvider waterProvider;

  const CustomWaterDialog({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.waterProvider,
  });

  @override
  State<CustomWaterDialog> createState() => _CustomWaterDialogState();
}

class _CustomWaterDialogState extends State<CustomWaterDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Özel Miktar Ekle'),
      content: Form(
        key: widget.formKey,
        child: TextFormField(
          controller: widget.amountController,
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
            if (widget.formKey.currentState?.validate() ?? false) {
              final amount = int.parse(widget.amountController.text);
              widget.waterProvider.addWater(amount);
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
  }
}

class EditWaterDialog extends StatefulWidget {
  final WaterProvider waterProvider;
  final WaterLogModel log;

  const EditWaterDialog({
    super.key,
    required this.waterProvider,
    required this.log,
  });

  @override
  State<EditWaterDialog> createState() => _EditWaterDialogState();
}

class _EditWaterDialogState extends State<EditWaterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.log.amount.toString());
    _selectedTime = TimeOfDay.fromDateTime(widget.log.time);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.nightSky,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Su Kaydını Düzenle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
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
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kayıt Saati'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time, color: AppColors.primary),
              onTap: () => _selectTime(context),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final amount = int.parse(_amountController.text);
              
              // Günün tarihiyle seçilen saati birleştir
              final originalDate = widget.log.time;
              final newDateTime = DateTime(
                originalDate.year,
                originalDate.month,
                originalDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );

              widget.waterProvider.updateWaterLog(widget.log.id, amount, newDateTime);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Su tüketim kaydı güncellendi: $amount ml'),
                    duration: const Duration(seconds: 2),
                  ),
                );
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
